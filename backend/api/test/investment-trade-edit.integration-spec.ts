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

describe('BE-P4-E03 investment purchases HTTP + PostgreSQL', () => {
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

  const create = (body: object) => request('POST', '/investments', {
    clientId: randomUUID(), kind: 'gold', name: 'Vàng SJC', currencyCode: 'VND', unit: 'chi', ...body,
  });
  const buy = (over: object) => ({ clientId: randomUUID(), quantity: '5', priceMinor: '7000000', tradedOn: '2026-09-10', ...over });
  const trades = async (id: string) => (await request('GET', `/investments/${id}/trades`)).body.items;
  const netWorthVnd = async () => {
    const res = await request('GET', '/reports/net-worth');
    return BigInt(res.body.items.find((item: { currency: string }) => item.currency === 'VND')?.netWorthMinor ?? '0');
  };

  it('creates a position with its first buy; the unit price becomes the latest price', async () => {
    const cash = await wallet();
    const res = await create({ initialTrade: buy({ accountId: cash.id }) });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({
      quantity: '5', costBasisMinor: '35000000', averageCostMinor: '7000000', currentValueMinor: '35000000', unrealizedMinor: '0', unrealizedBps: '0',
      latestPrice: { priceMinor: '7000000', source: 'trade' },
    });
    expect(await balance(cash.id)).toBe(465_000_000n);
    const [lot] = await trades(res.body.id);
    expect(lot).toMatchObject({ side: 'buy', amountMinor: '35000000', unitPriceMinor: '7000000', accountId: cash.id, note: null, unrealizedBps: '0' });
  });

  it('an already-owned buy adds value without touching any wallet or setting a price', async () => {
    const cash = await wallet();
    const before = await netWorthVnd();
    const res = await create({ name: 'Vàng nhẫn', initialTrade: buy({ quantity: '2', priceMinor: undefined, amountMinor: '12000000', accountId: null }) });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ quantity: '2', costBasisMinor: '12000000', latestPrice: null, valuationBasis: 'cost' });
    expect(await balance(cash.id)).toBe(500_000_000n);
    expect(await netWorthVnd() - before).toBe(12_000_000n);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    const sale = await request('POST', `/investments/${res.body.id}/trades`, { clientId: randomUUID(), side: 'sell', quantity: '1', amountMinor: '8000000', accountId: null, tradedOn: '2026-11-01' });
    expect(sale.status).toBe(400);
  });

  it('a new clientId with the same kind and name adds the buy to the existing position', async () => {
    const cash = await wallet();
    const first = await create({ initialTrade: buy({ accountId: cash.id }) });
    const second = await create({ name: '  vàng sjc ', initialTrade: buy({ quantity: '2', priceMinor: '7500000', tradedOn: '2026-09-25', accountId: cash.id }) });
    expect(second.status).toBe(201);
    expect(second.body).toMatchObject({ id: first.body.id, quantity: '7', costBasisMinor: '50000000', averageCostMinor: '7142857' });
    expect(await prisma.investment.count({ where: { userId: owner } })).toBe(1);
    const retry = await create({ clientId: first.body.clientId, initialTrade: buy({ accountId: cash.id }) });
    expect(retry.status).toBe(200);
  });

  it('a sell with a unit price books proceeds to the chosen wallet and becomes the latest price', async () => {
    const cash = await wallet();
    const bank = await wallet();
    const gold = (await create({ initialTrade: buy({ quantity: '7', priceMinor: undefined, amountMinor: '50000000', accountId: cash.id }) })).body;
    const sale = await request('POST', `/investments/${gold.id}/trades`, {
      clientId: randomUUID(), side: 'sell', quantity: '3', priceMinor: '8000000', accountId: bank.id, tradedOn: '2026-11-01',
    });
    expect(sale.status).toBe(201);
    expect(sale.body).toMatchObject({ quantity: '4', latestPrice: { priceMinor: '8000000', source: 'trade' }, currentValueMinor: '32000000' });
    expect(await balance(bank.id)).toBe(524_000_000n);
    const sold = (await trades(gold.id)).find((item: { side: string }) => item.side === 'sell');
    expect(sold).toMatchObject({ amountMinor: '24000000', realizedMinor: '2571429', currentValueMinor: null });
  });

  it('editing a buy moves its wallet leg and replays the realized gain of later sells', async () => {
    const cash = await wallet();
    const bank = await wallet();
    const gold = (await create({ initialTrade: buy({ quantity: '10', priceMinor: undefined, amountMinor: '70000000', accountId: cash.id }) })).body;
    const sold = await request('POST', `/investments/${gold.id}/trades`, { clientId: randomUUID(), side: 'sell', quantity: '6', amountMinor: '48000000', accountId: cash.id, tradedOn: '2026-10-14' });
    const [, firstBuy] = await trades(gold.id);
    const edited = await request('PATCH', `/investments/${gold.id}/trades/${firstBuy.id}`, {
      version: sold.body.version, amountMinor: '60000000', accountId: bank.id, tradedOn: '2026-09-01', note: 'Mua tại tiệm quen',
    });
    expect(edited.status).toBe(200);
    expect(edited.body).toMatchObject({ quantity: '4', costBasisMinor: '24000000' });
    expect(await balance(cash.id)).toBe(548_000_000n);
    expect(await balance(bank.id)).toBe(440_000_000n);
    const after = await trades(gold.id);
    expect(after.find((item: { side: string }) => item.side === 'sell').realizedMinor).toBe('12000000');
    expect(after.find((item: { side: string }) => item.side === 'buy')).toMatchObject({ tradedOn: '2026-09-01', note: 'Mua tại tiệm quen' });
    const leg = await prisma.transaction.findFirstOrThrow({ where: { userId: owner, amountMinor: -60_000_000n } });
    expect([leg.type, leg.accountId, leg.occurredOn.toISOString().slice(0, 10)]).toEqual(['investment', bank.id, '2026-09-01']);
    expect((await request('PATCH', `/investments/${gold.id}/trades/${firstBuy.id}`, { version: sold.body.version, amountMinor: '1' })).status).toBe(409);
    const sell = after.find((item: { side: string }) => item.side === 'sell');
    expect((await request('PATCH', `/investments/${gold.id}/trades/${sell.id}`, { version: edited.body.version, amountMinor: '1' })).status).toBe(422);
    expect((await request('PATCH', `/transactions/${leg.id}`, { version: leg.version, notes: 'x' })).status).toBe(400);
  });

  it('switching a buy to already owned and back removes then restores the same wallet leg', async () => {
    const cash = await wallet();
    let gold = (await create({ initialTrade: buy({ accountId: cash.id }) })).body;
    const [lot] = await trades(gold.id);
    gold = (await request('PATCH', `/investments/${gold.id}/trades/${lot.id}`, { version: gold.version, accountId: null })).body;
    expect(await balance(cash.id)).toBe(500_000_000n);
    expect((await trades(gold.id))[0].accountId).toBeNull();
    gold = (await request('PATCH', `/investments/${gold.id}/trades/${lot.id}`, { version: gold.version, accountId: cash.id, quantity: '4' })).body;
    expect(gold).toMatchObject({ quantity: '4', costBasisMinor: '35000000' });
    expect(await balance(cash.id)).toBe(465_000_000n);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(1);
  });

  it('deleting a buy gives the money back; one a sell relied on is refused; the last one removes the position', async () => {
    const cash = await wallet();
    let gold = (await create({ initialTrade: buy({ quantity: '5', priceMinor: undefined, amountMinor: '35000000', accountId: cash.id }) })).body;
    gold = (await request('POST', `/investments/${gold.id}/trades`, buy({ side: 'buy', quantity: '2', priceMinor: undefined, amountMinor: '15000000', accountId: cash.id, tradedOn: '2026-09-25' }))).body;
    gold = (await request('POST', `/investments/${gold.id}/trades`, { clientId: randomUUID(), side: 'sell', quantity: '6', amountMinor: '48000000', accountId: cash.id, tradedOn: '2026-10-14' })).body;
    const buys = (await trades(gold.id)).filter((item: { side: string }) => item.side === 'buy');
    const refused = await request('DELETE', `/investments/${gold.id}/trades/${buys[1].id}?version=${gold.version}`);
    expect(refused.status).toBe(422);
    expect(refused.body.error.code).toBe('INVESTMENT_OVERSELL');
    expect(await balance(cash.id)).toBe(500_000_000n - 50_000_000n + 48_000_000n);

    const solo = (await create({ name: 'Nhẫn', initialTrade: buy({ quantity: '1', priceMinor: undefined, amountMinor: '8000000', accountId: cash.id }) })).body;
    const [only] = await trades(solo.id);
    expect((await request('DELETE', `/investments/${solo.id}/trades/${only.id}?version=${solo.version - 1}`)).status).toBe(409);
    const gone = await request('DELETE', `/investments/${solo.id}/trades/${only.id}?version=${solo.version}`);
    expect(gone.status).toBe(204);
    expect((await request('GET', `/investments/${solo.id}`)).status).toBe(404);
    expect(await balance(cash.id)).toBe(500_000_000n - 50_000_000n + 48_000_000n);
    expect(await prisma.transaction.count({ where: { userId: owner, deletedAt: { not: null } } })).toBe(1);
  });

  it('a deposit is created with its money in one call', async () => {
    const bank = await wallet();
    const res = await request('POST', '/investments', {
      clientId: randomUUID(), kind: 'savings_deposit', name: 'VCB 12 tháng', currencyCode: 'VND', unit: 'deposit',
      interestRateBps: 650, startDate: '2026-06-01', maturityDate: '2027-06-01',
      initialTrade: { clientId: randomUUID(), quantity: '1', amountMinor: '100000000', accountId: bank.id, tradedOn: '2026-06-01' },
    });
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ quantity: '1', costBasisMinor: '100000000', valuationBasis: 'deposit', latestPrice: null });
    expect(await balance(bank.id)).toBe(400_000_000n);
  });

  it('summarises per kind with shares and percentages, filters the list by kind and tracks value over time', async () => {
    const cash = await wallet();
    const gold = (await create({ initialTrade: buy({ quantity: '5', priceMinor: '7000000', accountId: cash.id }) })).body;
    await request('POST', `/investments/${gold.id}/prices`, { clientId: randomUUID(), priceMinor: '8000000', quotedAt: '2026-11-05T02:00:00Z' });
    await create({ kind: 'crypto', name: 'ETH', unit: 'coin', initialTrade: buy({ quantity: '0.5', priceMinor: undefined, amountMinor: '10000000', accountId: null }) });
    const summary = await request('GET', '/investments/summary');
    expect(summary.body.totals).toEqual([{
      currencyCode: 'VND', costBasisMinor: '45000000', currentValueMinor: '50000000', unrealizedMinor: '5000000', unrealizedBps: '1429', unpricedCount: 1,
    }]);
    expect(summary.body.byKind.map((row: { kind: string; shareBps: string; unrealizedBps: string | null }) => [row.kind, row.shareBps, row.unrealizedBps]))
      .toEqual([['gold', '8000', '1429'], ['crypto', '2000', null]]);
    const onlyGold = await request('GET', '/investments?kind=gold');
    expect(onlyGold.body.items.map((item: { id: string }) => item.id)).toEqual([gold.id]);
    expect((await request('GET', '/investments?kind=house')).status).toBe(400);
    const history = await request('GET', `/reports/investments/history?window=3m&on=2026-11-06&investmentId=${gold.id}`);
    expect(history.status).toBe(200);
    expect(history.body.points.at(-1).items).toEqual([{ currency: 'VND', valueMinor: '40000000' }]);
    const byKind = await request('GET', '/reports/investments/history?window=3m&on=2026-11-06&kind=crypto');
    expect(byKind.body.points.at(-1).items).toEqual([{ currency: 'VND', valueMinor: '10000000' }]);
    expect((await request('GET', '/reports/investments/history?window=9y')).status).toBe(400);
  });

  it('keeps every user to their own positions and trades', async () => {
    const cash = await wallet();
    const gold = (await create({ initialTrade: buy({ accountId: cash.id }) })).body;
    const [lot] = await trades(gold.id);
    const other = await user();
    expect((await request('PATCH', `/investments/${gold.id}/trades/${lot.id}`, { version: gold.version, amountMinor: '1' }, other.bearer)).status).toBe(404);
    expect((await request('DELETE', `/investments/${gold.id}/trades/${lot.id}?version=${gold.version}`, undefined, other.bearer)).status).toBe(404);
    expect((await request('GET', `/reports/investments/history?window=3m&investmentId=${gold.id}`, undefined, other.bearer)).body.points.every(
      (point: { items: unknown[] }) => point.items.length === 0)).toBe(true);
    expect((await request('DELETE', `/investments/${gold.id}/trades/${lot.id}?version=${gold.version}`, undefined, '')).status).toBe(401);
  });
});
