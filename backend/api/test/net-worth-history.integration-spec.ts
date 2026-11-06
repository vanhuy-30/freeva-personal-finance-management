import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { InvestmentModule } from '../src/modules/investments/investment.module';
import { PersonalDebtModule } from '../src/modules/personal-debts/personal-debt.module';
import { ReportModule } from '../src/modules/reports/report.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

type Item = { currency: string; assetsMinor: string; liabilitiesMinor: string; netWorthMinor: string };
type Point = { from: string; to: string; asOf: string; items: Item[] };

describe('BE-P4-E02 net worth history HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule, PersonalDebtModule, InvestmentModule,
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
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1 } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) } });
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
      await prisma.personalDebtPayment.deleteMany({ where });
      await prisma.personalDebt.deleteMany({ where });
      await prisma.transactionTag.deleteMany({ where: { transaction: where } });
      await prisma.transaction.deleteMany({ where });
      await prisma.category.deleteMany({ where });
      await prisma.financialAccount.deleteMany({ where });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where });
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

  const wallet = (type: 'cash' | 'bank' | 'credit', initialBalanceMinor: bigint) => prisma.financialAccount.create({
    data: { userId: owner, clientId: randomUUID(), name: 'W', type, currencyCode: 'VND', initialBalanceMinor },
  });

  const ledger = (accountId: string, type: 'income' | 'expense' | 'transfer', amountMinor: bigint, occurredOn: string, transferGroupId?: string) =>
    prisma.transaction.create({ data: {
      userId: owner, clientId: randomUUID(), accountId, currencyCode: 'VND', type, amountMinor,
      occurredOn: new Date(`${occurredOn}T00:00:00.000Z`), transferGroupId,
    } });

  /**
   * VND, six months May..Oct 2026. Cash starts 100m, bank 0, credit card owes 5m.
   * Aug 10 +20m income, Aug 20 -3m expense, Sep 5 transfer 30m cash -> bank, Sep 10 buy 10 chi of gold for 70m,
   * gold priced 7,5m (Sep 20) then 8m (Oct 12), Oct 5 lend 3m from the bank, Oct 14 sell 4 chi for 32m.
   */
  async function story() {
    const cash = await wallet('cash', 100_000_000n);
    const bank = await wallet('bank', 0n);
    await wallet('credit', -5_000_000n);
    const income = await ledger(cash.id, 'income', 20_000_000n, '2026-08-10');
    await ledger(cash.id, 'expense', -3_000_000n, '2026-08-20');
    const group = randomUUID();
    await ledger(cash.id, 'transfer', -30_000_000n, '2026-09-05', group);
    await ledger(bank.id, 'transfer', 30_000_000n, '2026-09-05', group);
    const gold = (await request('POST', '/investments', { clientId: randomUUID(), kind: 'gold', name: 'SJC', currencyCode: 'VND', unit: 'chi' })).body;
    expect((await request('POST', `/investments/${gold.id}/trades`, {
      clientId: randomUUID(), side: 'buy', quantity: '10', amountMinor: '70000000', accountId: cash.id, tradedOn: '2026-09-10',
    })).status).toBe(201);
    await request('POST', `/investments/${gold.id}/prices`, { clientId: randomUUID(), priceMinor: '7500000', quotedAt: '2026-09-20T05:00:00.000Z' });
    await request('POST', `/investments/${gold.id}/prices`, { clientId: randomUUID(), priceMinor: '8000000', quotedAt: '2026-10-12T05:00:00.000Z' });
    expect((await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'lent', counterparty: 'Minh', amountMinor: '3000000', accountId: bank.id, occurredOn: '2026-10-05',
    })).status).toBe(201);
    expect((await request('POST', `/investments/${gold.id}/trades`, {
      clientId: randomUUID(), side: 'sell', quantity: '4', amountMinor: '32000000', accountId: cash.id, tradedOn: '2026-10-14',
    })).status).toBe(201);
    return { cash, bank, income, gold };
  }

  const history = async (query: string) => {
    const res = await request('GET', `/reports/net-worth/history?${query}`);
    return { status: res.status, points: (res.body?.points ?? []) as Point[], body: res.body };
  };
  const nets = (points: Point[]) => points.map(point => point.items[0]?.netWorthMinor ?? '0');

  it('walks six months of income, expense, transfer, a position and a loan to a friend', async () => {
    await story();
    const result = await history('window=6m&on=2026-10-15');
    expect(result.status).toBe(200);
    expect(result.body).toMatchObject({ window: '6m' });
    expect(result.points.map(point => point.to)).toEqual(['2026-05-31', '2026-06-30', '2026-07-31', '2026-08-31', '2026-09-30', '2026-10-31']);
    expect(result.points.map(point => point.asOf)).toEqual(result.points.map(point => point.to));
    // May-Jul: 100m cash - 5m card. Aug: +20m -3m. Sep: transfer moves nothing, buying gold at 7,5m adds 5m. Oct: gold at 8m adds 5m more.
    expect(nets(result.points)).toEqual(['95000000', '95000000', '95000000', '112000000', '117000000', '122000000']);
    expect(result.points[3]!.items).toEqual([{ currency: 'VND', assetsMinor: '117000000', liabilitiesMinor: '-5000000', netWorthMinor: '112000000' }]);
    // Sep: cash 17m + bank 30m + 10 chi x 7,5m
    expect(result.points[4]!.items).toEqual([{ currency: 'VND', assetsMinor: '122000000', liabilitiesMinor: '-5000000', netWorthMinor: '117000000' }]);
    // Oct: cash 49m + bank 27m + 6 chi x 8m + 3m lent
    expect(result.points[5]!.items).toEqual([{ currency: 'VND', assetsMinor: '127000000', liabilitiesMinor: '-5000000', netWorthMinor: '122000000' }]);
  });

  it('a transfer and a purchase move money between parts without changing the total', async () => {
    await story();
    const days = (await history('window=30d&on=2026-09-25')).points;
    const net = (day: string) => days.find(point => point.asOf === day)!.items[0]!.netWorthMinor;
    expect(net('2026-09-04')).toBe(net('2026-09-05'));
    // gold has no price yet on Sep 9-10, so it stands in at cost: 70m left the wallet and 70m entered the position.
    expect(net('2026-09-09')).toBe(net('2026-09-10'));
    expect(net('2026-09-19')).toBe('112000000');
    expect(net('2026-09-20')).toBe('117000000');
    expect(days).toHaveLength(30);
  });

  it('the latest point is the live net worth', async () => {
    await story();
    const live = (await request('GET', '/reports/net-worth')).body.items;
    for (const window of ['7d', '30d', '3m', '1y', 'all']) {
      const points = (await history(`window=${window}`)).points;
      expect(points.at(-1)!.items).toEqual(live);
    }
  });

  it('editing the past moves every later point', async () => {
    const { income } = await story();
    await prisma.transaction.update({ where: { id: income.id }, data: { deletedAt: new Date() } });
    expect(nets((await history('window=6m&on=2026-10-15')).points)).toEqual(
      ['95000000', '95000000', '95000000', '92000000', '97000000', '102000000']);
  });

  it('a lend settled later is still counted on the days it was open', async () => {
    const { bank } = await story();
    const debt = await prisma.personalDebt.findFirstOrThrow({ where: { userId: owner } });
    expect((await request('POST', `/personal-debts/${debt.id}/payments`, {
      clientId: randomUUID(), amountMinor: '3000000', paidOn: '2026-11-02', accountId: bank.id,
    })).status).toBe(201);
    await prisma.personalDebt.update({ where: { id: debt.id }, data: { archivedAt: new Date() } });
    const oct = (await history('window=6m&on=2026-10-15')).points.at(-1)!;
    expect(oct.items[0]!.netWorthMinor).toBe('122000000');
  });

  it('all starts at the first activity of any kind', async () => {
    await story();
    const all = await history('window=all&on=2026-10-15');
    expect(all.points.map(point => point.from)).toEqual(['2026-01-01']);
    expect(all.points[0]!.items[0]!.netWorthMinor).toBe('122000000');
    expect((await history('window=all')).points.length).toBeGreaterThanOrEqual(1);
  });

  it('an empty account gets empty points and other users see nothing of it', async () => {
    await story();
    const stranger = await user();
    const result = await request('GET', '/reports/net-worth/history?window=7d', undefined, stranger.bearer);
    expect(result.status).toBe(200);
    expect(result.body.points).toHaveLength(7);
    expect(result.body.points.every((point: Point) => point.items.length === 0)).toBe(true);
  });

  it('validates the window and the session', async () => {
    expect((await request('GET', '/reports/net-worth/history?window=decade')).status).toBe(400);
    expect((await request('GET', '/reports/net-worth/history')).status).toBe(400);
    expect((await request('GET', '/reports/net-worth/history?window=7d&on=2026-02-30')).status).toBe(400);
    expect((await request('GET', '/reports/net-worth/history?window=7d', undefined, '')).status).toBe(401);
  });
});
