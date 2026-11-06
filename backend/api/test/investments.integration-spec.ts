import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { InvestmentModule } from '../src/modules/investments/investment.module';
import { ReportModule } from '../src/modules/reports/report.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P4-E01 investments HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let token: string;
  const fixtureUsers: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule, InvestmentModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
  });

  async function user() {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) },
    });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user();
    owner = first.id;
    token = first.bearer;
  });

  afterAll(async () => {
    if (prisma) {
      const where = { userId: { in: fixtureUsers } };
      await prisma.investmentPrice.deleteMany({ where });
      await prisma.investmentTrade.deleteMany({ where });
      await prisma.investment.deleteMany({ where });
      await prisma.transactionTag.deleteMany({ where: { transaction: where } });
      await prisma.transaction.deleteMany({ where });
      await prisma.category.deleteMany({ where });
      await prisma.financialAccount.deleteMany({ where });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function request(method: string, path: string, body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1${path}`, {
      method,
      headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }

  const wallet = (userId = owner, currencyCode = 'VND', initialBalanceMinor = 500_000_000n) => prisma.financialAccount.create({
    data: { userId, clientId: randomUUID(), name: 'Wallet', type: 'cash', currencyCode, initialBalanceMinor },
  });

  const balance = async (accountId: string) => {
    const account = await prisma.financialAccount.findUniqueOrThrow({ where: { id: accountId } });
    const sum = await prisma.transaction.aggregate({ where: { accountId, deletedAt: null }, _sum: { amountMinor: true } });
    return account.initialBalanceMinor + (sum._sum.amountMinor ?? 0n);
  };

  const createGold = async () => {
    const res = await request('POST', '/investments', { clientId: randomUUID(), kind: 'gold', name: 'SJC', currencyCode: 'VND', unit: 'chi' });
    expect(res.status).toBe(201);
    return res.body;
  };

  const trade = (id: string, body: object) => request('POST', `/investments/${id}/trades`, { clientId: randomUUID(), tradedOn: '2026-11-01', ...body });

  it('creates a position idempotently and audits it once', async () => {
    const clientId = randomUUID();
    const body = { clientId, kind: 'gold', name: 'SJC', currencyCode: 'VND', unit: 'chi' };
    const first = await request('POST', '/investments', body);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({ kind: 'gold', quantity: '0', costBasisMinor: '0', valuationBasis: 'cost', latestPrice: null });
    expect((await request('POST', '/investments', body)).status).toBe(200);
    expect((await request('POST', '/investments', { ...body, name: 'Other' })).status).toBe(409);
    expect(await prisma.auditEvent.count({ where: { action: 'investment.create', actorId: owner } })).toBe(1);
  });

  it('validates kind, unit and deposit terms', async () => {
    const base = { clientId: randomUUID(), kind: 'gold', name: 'X', currencyCode: 'VND', unit: 'chi' };
    expect((await request('POST', '/investments', { ...base, unit: 'coin' })).status).toBe(400);
    expect((await request('POST', '/investments', { ...base, clientId: randomUUID(), kind: 'savings_deposit', unit: 'deposit' })).status).toBe(400);
    expect((await request('POST', '/investments', { ...base, clientId: randomUUID(), interestRateBps: 600 })).status).toBe(400);
    expect((await request('POST', '/investments', { ...base, clientId: randomUUID(), currencyCode: 'ZZZ' })).status).toBe(400);
    expect((await request('POST', '/investments', base, '')).status).toBe(401);
  });

  it('buy -> add -> partial sell moves wallet money through investment legs, never income or expense', async () => {
    const source = await wallet();
    const gold = await createGold();
    const first = await trade(gold.id, { side: 'buy', quantity: '10', amountMinor: '70000000', accountId: source.id });
    expect(first.status).toBe(201);
    const second = await trade(gold.id, { side: 'buy', quantity: '5', amountMinor: '37500000', accountId: source.id });
    expect(second.body).toMatchObject({ quantity: '15', costBasisMinor: '107500000' });
    expect(await balance(source.id)).toBe(500_000_000n - 107_500_000n);

    const sale = await trade(gold.id, { side: 'sell', quantity: '6', amountMinor: '48000000', accountId: source.id });
    expect(sale.status).toBe(201);
    expect(sale.body).toMatchObject({ quantity: '9', costBasisMinor: '64500000' });
    expect(await balance(source.id)).toBe(500_000_000n - 107_500_000n + 48_000_000n);

    const types = await prisma.transaction.findMany({ where: { accountId: source.id }, orderBy: { createdAt: 'asc' } });
    expect(types.map(row => [row.type, row.amountMinor, row.categoryId])).toEqual([
      ['investment', -70_000_000n, null], ['investment', -37_500_000n, null], ['investment', 48_000_000n, null],
    ]);
    const trades = await request('GET', `/investments/${gold.id}/trades`);
    expect(trades.body.items.find((item: { side: string }) => item.side === 'sell')).toMatchObject({ realizedMinor: '5000000', quantity: '6' });
  });

  it('replays a trade without moving money twice and rejects a changed replay', async () => {
    const source = await wallet();
    const gold = await createGold();
    const body = { clientId: randomUUID(), side: 'buy', quantity: '1', amountMinor: '7000000', accountId: source.id, tradedOn: '2026-11-01' };
    expect((await request('POST', `/investments/${gold.id}/trades`, body)).status).toBe(201);
    expect((await request('POST', `/investments/${gold.id}/trades`, body)).status).toBe(200);
    expect(await balance(source.id)).toBe(493_000_000n);
    expect((await request('POST', `/investments/${gold.id}/trades`, { ...body, amountMinor: '7000001' })).status).toBe(409);
  });

  it('rejects overselling, a wallet in another currency and an invalid quantity', async () => {
    const source = await wallet();
    const usd = await wallet(owner, 'USD', 1_000_000n);
    const gold = await createGold();
    await trade(gold.id, { side: 'buy', quantity: '2', amountMinor: '14000000', accountId: source.id });
    expect((await trade(gold.id, { side: 'sell', quantity: '2.00000001', amountMinor: '1', accountId: source.id })).status).toBe(422);
    expect((await trade(gold.id, { side: 'buy', quantity: '1', amountMinor: '100', accountId: usd.id })).status).toBe(400);
    expect((await trade(gold.id, { side: 'buy', quantity: '1.123456789', amountMinor: '100', accountId: source.id })).status).toBe(400);
    expect((await trade(gold.id, { side: 'buy', quantity: '0', amountMinor: '100', accountId: source.id })).body.error.code).toBe('VALIDATION_ERROR');
    expect(await balance(source.id)).toBe(486_000_000n);
  });

  it('keeps crypto fractions exact and values them from the latest manual price', async () => {
    const source = await wallet(owner, 'VND', 5_000_000_000n);
    const crypto = (await request('POST', '/investments', { clientId: randomUUID(), kind: 'crypto', name: 'BTC', currencyCode: 'VND', unit: 'coin' })).body;
    const bought = await trade(crypto.id, { side: 'buy', quantity: '0.12345678', amountMinor: '300000000', accountId: source.id });
    expect(bought.body).toMatchObject({ quantity: '0.12345678', valuationBasis: 'cost', currentValueMinor: '300000000', unrealizedMinor: null });
    const priced = await request('POST', `/investments/${crypto.id}/prices`, { clientId: randomUUID(), priceMinor: '2500000000', quotedAt: '2026-11-05T09:00:00.000Z' });
    expect(priced.status).toBe(201);
    expect(priced.body).toMatchObject({
      valuationBasis: 'price', currentValueMinor: '308641950', unrealizedMinor: '8641950',
      latestPrice: { priceMinor: '2500000000', source: 'manual', quotedAt: '2026-11-05T09:00:00.000Z' },
    });
    const older = await request('POST', `/investments/${crypto.id}/prices`, { clientId: randomUUID(), priceMinor: '1', quotedAt: '2026-11-01T09:00:00.000Z' });
    expect(older.body.latestPrice.priceMinor).toBe('2500000000');
    expect((await request('GET', `/investments/${crypto.id}/prices`)).body.items).toHaveLength(2);
  });

  it('a savings deposit accrues simple interest, allows one buy and a full withdrawal', async () => {
    const source = await wallet();
    const deposit = (await request('POST', '/investments', {
      clientId: randomUUID(), kind: 'savings_deposit', name: 'VCB 12 tháng', currencyCode: 'VND', unit: 'deposit',
      interestRateBps: 1200, startDate: '2020-01-01', maturityDate: '2020-12-31',
    })).body;
    const bought = await trade(deposit.id, { side: 'buy', quantity: '1', amountMinor: '100000000', accountId: source.id });
    expect(bought.body).toMatchObject({ valuationBasis: 'deposit' });
    // 2020 is a leap year: 365 days from 2020-01-01 to 2020-12-31 -> 12.000.000
    expect(bought.body.currentValueMinor).toBe('112000000');
    expect((await trade(deposit.id, { side: 'buy', quantity: '1', amountMinor: '1', accountId: source.id })).status).toBe(422);
    expect((await request('POST', `/investments/${deposit.id}/prices`, { clientId: randomUUID(), priceMinor: '1', quotedAt: '2026-11-05T09:00:00.000Z' })).status).toBe(422);
    const out = await trade(deposit.id, { side: 'sell', quantity: '1', amountMinor: '112000000', accountId: source.id });
    expect(out.body).toMatchObject({ quantity: '0', costBasisMinor: '0' });
    const history = await request('GET', `/investments/${deposit.id}/trades`);
    expect(history.body.items.find((item: { side: string }) => item.side === 'sell').realizedMinor).toBe('12000000');
  });

  it('blocks editing or deleting an investment leg through /transactions', async () => {
    const source = await wallet();
    const gold = await createGold();
    await trade(gold.id, { side: 'buy', quantity: '1', amountMinor: '7000000', accountId: source.id });
    const leg = await prisma.transaction.findFirstOrThrow({ where: { accountId: source.id } });
    const patch = await request('PATCH', `/transactions/${leg.id}`, { version: leg.version, deleted: true });
    expect(patch.status).toBe(400);
    expect(await balance(source.id)).toBe(493_000_000n);
  });

  it('net worth adds the position value once; the wallet already paid for it', async () => {
    const source = await wallet(owner, 'VND', 100_000_000n);
    const gold = await createGold();
    await trade(gold.id, { side: 'buy', quantity: '5', amountMinor: '35000000', accountId: source.id });
    await request('POST', `/investments/${gold.id}/prices`, { clientId: randomUUID(), priceMinor: '8000000', quotedAt: '2026-11-05T09:00:00.000Z' });
    const worth = await request('GET', '/reports/net-worth');
    expect(worth.status).toBe(200);
    // wallet 65.000.000 + position 5 x 8.000.000 = 105.000.000
    expect(JSON.stringify(worth.body)).toContain('105000000');
    const summary = await request('GET', '/investments/summary');
    expect(summary.body.totals).toEqual([{ currencyCode: 'VND', costBasisMinor: '35000000', currentValueMinor: '40000000', unrealizedMinor: '5000000', unpricedCount: 0 }]);
  });

  it('income and expense reports ignore investment legs', async () => {
    const source = await wallet();
    const gold = await createGold();
    await trade(gold.id, { side: 'buy', quantity: '1', amountMinor: '7000000', accountId: source.id });
    const report = await request('GET', '/reports/cashflow?period=month&on=2026-11-15');
    expect(report.status).toBe(200);
    expect(report.body.totals).toEqual([]);
    const row = report.body.byAccount.find((item: { accountId: string }) => item.accountId === source.id);
    expect(row).toMatchObject({ incomeMinor: '0', expenseMinor: '0', investmentMinor: '-7000000', netMinor: '-7000000' });
  });

  it('archives only an empty position and isolates users', async () => {
    const source = await wallet();
    const gold = await createGold();
    await trade(gold.id, { side: 'buy', quantity: '1', amountMinor: '7000000', accountId: source.id });
    const held = (await request('GET', `/investments/${gold.id}`)).body;
    expect((await request('DELETE', `/investments/${gold.id}?version=${held.version}`)).status).toBe(409);
    const sold = await trade(gold.id, { side: 'sell', quantity: '1', amountMinor: '7500000', accountId: source.id });
    expect((await request('DELETE', `/investments/${gold.id}?version=${sold.body.version}`)).status).toBe(204);
    expect((await request('GET', '/investments')).body.items).toEqual([]);
    const stranger = await user();
    expect((await request('GET', `/investments/${gold.id}`, undefined, stranger.bearer)).status).toBe(404);
  });
});
