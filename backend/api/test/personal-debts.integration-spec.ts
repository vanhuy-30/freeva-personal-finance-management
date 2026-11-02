import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { PersonalDebtModule } from '../src/modules/personal-debts/personal-debt.module';
import { ReportModule } from '../src/modules/reports/report.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P3-007 personal debts HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule, PersonalDebtModule,
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
      await prisma.personalDebtPayment.deleteMany({ where });
      await prisma.personalDebt.deleteMany({ where });
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

  const wallet = (userId = owner, currencyCode = 'VND', initialBalanceMinor = 10_000_000n) => prisma.financialAccount.create({
    data: { userId, clientId: randomUUID(), name: 'Wallet', type: 'cash', currencyCode, initialBalanceMinor },
  });

  const balance = async (accountId: string) => {
    const account = await prisma.financialAccount.findUniqueOrThrow({ where: { id: accountId } });
    const sum = await prisma.transaction.aggregate({ where: { accountId, deletedAt: null }, _sum: { amountMinor: true } });
    return account.initialBalanceMinor + (sum._sum.amountMinor ?? 0n);
  };

  const lend = async (accountId: string, extra: object = {}) => {
    const res = await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'lent', counterparty: 'Minh', amountMinor: '3000000', accountId,
      occurredOn: '2026-11-01', ...extra,
    });
    expect(res.status).toBe(201);
    return res.body;
  };

  it('lending takes money out of the wallet as a debt leg, not an expense; replay is idempotent', async () => {
    const source = await wallet();
    const clientId = randomUUID();
    const body = { clientId, direction: 'lent', counterparty: 'Minh', amountMinor: '3000000', accountId: source.id, occurredOn: '2026-11-01', dueDate: '2026-11-30' };
    const first = await request('POST', '/personal-debts', body);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({ direction: 'lent', outstandingMinor: '3000000', paidMinor: '0', currencyCode: 'VND', status: 'open' });
    expect(await balance(source.id)).toBe(7_000_000n);
    const rows = await prisma.transaction.findMany({ where: { accountId: source.id } });
    expect(rows.map(row => [row.type, row.amountMinor, row.categoryId])).toEqual([['debt', -3_000_000n, null]]);
    expect((await request('POST', '/personal-debts', body)).status).toBe(200);
    expect(await balance(source.id)).toBe(7_000_000n);
    expect((await request('POST', '/personal-debts', { ...body, amountMinor: '5' })).status).toBe(409);
    expect(await prisma.auditEvent.count({ where: { action: 'personal_debt.create', actorId: owner } })).toBe(1);
  });

  it('borrowing brings money in and validates input', async () => {
    const source = await wallet();
    const created = await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'borrowed', counterparty: 'Lan', amountMinor: '2000000', accountId: source.id, occurredOn: '2026-11-01',
    });
    expect(created.status).toBe(201);
    expect(await balance(source.id)).toBe(12_000_000n);
    const base = { clientId: randomUUID(), direction: 'lent', counterparty: 'X', amountMinor: '1000', accountId: source.id, occurredOn: '2026-11-01' };
    expect((await request('POST', '/personal-debts', { ...base, amountMinor: '0' })).status).toBe(400);
    expect((await request('POST', '/personal-debts', { ...base, dueDate: '2026-10-01' })).status).toBe(400);
    expect((await request('POST', '/personal-debts', { ...base, accountId: randomUUID() })).status).toBe(400);
    expect((await request('POST', '/personal-debts', base, '')).status).toBe(401);
  });

  it('collects in several partial payments, settles, rejects overpayment, replays safely', async () => {
    const source = await wallet();
    const debt = await lend(source.id);
    const first = { clientId: randomUUID(), amountMinor: '1000000', paidOn: '2026-11-10' };
    const paid = await request('POST', `/personal-debts/${debt.id}/payments`, first);
    expect(paid.status).toBe(201);
    expect(paid.body).toMatchObject({ outstandingMinor: '2000000', paidMinor: '1000000', status: 'open' });
    expect(await balance(source.id)).toBe(8_000_000n);
    expect((await request('POST', `/personal-debts/${debt.id}/payments`, first)).status).toBe(200);
    expect(await balance(source.id)).toBe(8_000_000n);
    expect((await request('POST', `/personal-debts/${debt.id}/payments`, { ...first, amountMinor: '7' })).status).toBe(409);
    const over = await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '2000001', paidOn: '2026-11-11' });
    expect(over.status).toBe(422);
    expect(over.body.error.code).toBe('DEBT_OVERPAYMENT');
    const settled = await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '2000000', paidOn: '2026-11-12' });
    expect(settled.body).toMatchObject({ outstandingMinor: '0', status: 'settled' });
    expect(await balance(source.id)).toBe(10_000_000n);
    const history = await request('GET', `/personal-debts/${debt.id}/payments`);
    expect(history.body.items.map((item: { amountMinor: string }) => item.amountMinor)).toEqual(['2000000', '1000000']);
  });

  it('repaying what you borrowed sends money out', async () => {
    const source = await wallet();
    const debt = (await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'borrowed', counterparty: 'Lan', amountMinor: '2000000', accountId: source.id, occurredOn: '2026-11-01',
    })).body;
    await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '500000', paidOn: '2026-11-05' });
    expect(await balance(source.id)).toBe(11_500_000n);
  });

  it('keeps income, expense and savings reports unchanged and moves net worth by the receivable and payable', async () => {
    const source = await wallet();
    const before = (await request('GET', '/reports/net-worth')).body.items[0];
    expect(before).toMatchObject({ currency: 'VND', assetsMinor: '10000000', netWorthMinor: '10000000' });
    const debt = await lend(source.id);
    await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'borrowed', counterparty: 'Lan', amountMinor: '2000000', accountId: source.id, occurredOn: '2026-11-01',
    });
    const after = (await request('GET', '/reports/net-worth')).body.items[0];
    // Wallet 9.000.000 + receivable 3.000.000 = 12.000.000 assets; owes 2.000.000; net unchanged by the two moves.
    expect(after).toMatchObject({ assetsMinor: '12000000', liabilitiesMinor: '-2000000', netWorthMinor: '10000000' });
    await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '400000', paidOn: '2026-11-10' });
    const partly = (await request('GET', '/reports/net-worth')).body.items[0];
    expect(partly).toMatchObject({ assetsMinor: '12000000', liabilitiesMinor: '-2000000', netWorthMinor: '10000000' });
    const cashflow = await request('GET', '/reports/cashflow?period=month&on=2026-11-15');
    expect(cashflow.body.totals).toEqual([]);
    const byAccount = cashflow.body.byAccount.find((row: { accountId: string }) => row.accountId === source.id);
    expect(byAccount).toMatchObject({ incomeMinor: '0', expenseMinor: '0', debtMinor: '-600000' });
  });

  it('lists who owes me and whom I owe with totals, and hides settled and archived debts', async () => {
    const source = await wallet();
    const owed = await lend(source.id, { counterparty: 'Minh' });
    await request('POST', '/personal-debts', {
      clientId: randomUUID(), direction: 'borrowed', counterparty: 'Lan', amountMinor: '2000000', accountId: source.id, occurredOn: '2026-11-01',
    });
    const done = await lend(source.id, { counterparty: 'Hà', amountMinor: '500000' });
    await request('POST', `/personal-debts/${done.id}/payments`, { clientId: randomUUID(), amountMinor: '500000', paidOn: '2026-11-02' });
    const summary = (await request('GET', '/personal-debts/summary')).body;
    expect(summary.owedToMe.map((row: { id: string }) => row.id)).toEqual([owed.id]);
    expect(summary.iOwe).toHaveLength(1);
    expect(summary.totals).toEqual([{ currencyCode: 'VND', receivableMinor: '3000000', payableMinor: '2000000', receivableCount: 1, payableCount: 1 }]);
    const archived = await request('DELETE', `/personal-debts/${done.id}?version=${done.version + 1}`);
    expect(archived.status).toBe(204);
    expect((await request('GET', '/personal-debts')).body.items.map((row: { id: string }) => row.id)).not.toContain(done.id);
  });

  it('updates the note and due date with a version, flags overdue, and refuses to archive an open debt', async () => {
    const source = await wallet();
    const debt = await lend(source.id, { dueDate: '2026-11-30' });
    const updated = await request('PATCH', `/personal-debts/${debt.id}`, { version: debt.version, dueDate: '2026-11-01', note: 'Tiền ăn' });
    expect(updated.status).toBe(200);
    expect(updated.body).toMatchObject({ note: 'Tiền ăn', dueDate: '2026-11-01', status: 'overdue', version: debt.version + 1 });
    expect((await request('PATCH', `/personal-debts/${debt.id}`, { version: debt.version, note: 'x' })).status).toBe(409);
    expect((await request('DELETE', `/personal-debts/${debt.id}?version=${updated.body.version}`)).status).toBe(409);
  });

  it('blocks editing or deleting a debt leg through /transactions and keeps other owners out', async () => {
    const source = await wallet();
    const debt = await lend(source.id);
    const leg = await prisma.transaction.findFirstOrThrow({ where: { accountId: source.id, type: 'debt' } });
    const del = await request('DELETE', `/transactions/${leg.id}?version=${leg.version}`);
    expect(del.status).toBe(400);
    expect(await balance(source.id)).toBe(7_000_000n);
    const stranger = await user();
    expect((await request('GET', `/personal-debts/${debt.id}`, undefined, stranger.bearer)).status).toBe(404);
    expect((await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '1', paidOn: '2026-11-02' }, stranger.bearer)).status).toBe(404);
  });

  it('rejects a payment wallet in another currency', async () => {
    const source = await wallet();
    await prisma.currency.upsert({ where: { code: 'USD' }, update: {}, create: { code: 'USD', minorDigits: 2, name: 'US dollar' } });
    const usd = await wallet(owner, 'USD', 0n);
    const debt = await lend(source.id);
    const res = await request('POST', `/personal-debts/${debt.id}/payments`, { clientId: randomUUID(), amountMinor: '1000', accountId: usd.id, paidOn: '2026-11-02' });
    expect(res.status).toBe(400);
  });
});
