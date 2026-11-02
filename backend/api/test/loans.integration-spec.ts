import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { LoanModule } from '../src/modules/loans/loan.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P3-E02 loans HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, LoanModule,
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
      await prisma.loanPayment.deleteMany({ where });
      await prisma.loan.deleteMany({ where });
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

  const wallet = (userId = owner, currencyCode = 'VND') => prisma.financialAccount.create({
    data: { userId, clientId: randomUUID(), name: 'Wallet', type: 'cash', currencyCode, initialBalanceMinor: 0n },
  });

  const category = (userId = owner) => prisma.category.create({
    data: { userId, clientId: randomUUID(), name: 'Trả nợ', kind: 'expense' },
  });

  async function createLoan(extra: object = {}) {
    const res = await request('POST', '/loans', {
      clientId: randomUUID(), kind: 'personal', name: 'Vay mua xe', currencyCode: 'VND', principalMinor: '100000000',
      interestRateBps: 1200, installmentMinor: '8884879', frequency: 'monthly', startDate: '2026-11-01',
      nextDueDate: '2026-12-01', ...extra,
    });
    expect(res.status).toBe(201);
    return res.body;
  }

  const balance = async (accountId: string) => {
    const sum = await prisma.transaction.aggregate({ where: { accountId, deletedAt: null }, _sum: { amountMinor: true } });
    return sum._sum.amountMinor ?? 0n;
  };

  it('creates, replays the same clientId, rejects different content, audits the create', async () => {
    const clientId = randomUUID();
    const body = {
      clientId, kind: 'mortgage', name: 'Nhà', currencyCode: 'VND', principalMinor: '100000000', interestRateBps: 1200,
      installmentMinor: '8884879', frequency: 'monthly', startDate: '2026-11-01',
    };
    const first = await request('POST', '/loans', body);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({
      outstandingMinor: '100000000', paidMinor: '0', percentBps: 0, periodInterestMinor: '1000000',
      remainingPeriods: 12, status: 'active',
    });
    expect((await request('POST', '/loans', body)).status).toBe(200);
    expect((await request('POST', '/loans', { ...body, principalMinor: '5' })).status).toBe(409);
    expect(await prisma.auditEvent.count({ where: { action: 'loan.create', actorId: owner } })).toBe(1);
  });

  it('validates input', async () => {
    const base = { clientId: randomUUID(), kind: 'other', name: 'X', currencyCode: 'VND', principalMinor: '1000', interestRateBps: 0, frequency: 'monthly', startDate: '2026-11-01' };
    expect((await request('POST', '/loans', { ...base, principalMinor: '0' })).status).toBe(400);
    expect((await request('POST', '/loans', { ...base, outstandingMinor: '2000' })).status).toBe(400);
    expect((await request('POST', '/loans', { ...base, endDate: '2026-10-01' })).status).toBe(400);
    expect((await request('POST', '/loans', { ...base, currencyCode: 'ZZZ' })).status).toBe(400);
    expect((await request('POST', '/loans', base, '')).status).toBe(401);
  });

  it('pays with an automatic split: two expenses, balance and due date move, replay is idempotent', async () => {
    const source = await wallet();
    const loan = await createLoan();
    const principalCategory = await category();
    const interestCategory = await category();
    const clientId = randomUUID();
    const body = {
      clientId, amountMinor: '8884879', accountId: source.id, paidOn: '2026-12-01',
      principalCategoryId: principalCategory.id, interestCategoryId: interestCategory.id,
    };
    const paid = await request('POST', `/loans/${loan.id}/payments`, body);
    expect(paid.status).toBe(201);
    expect(paid.body).toMatchObject({ outstandingMinor: '92115121', paidMinor: '7884879', nextDueDate: '2027-01-01' });
    expect(await balance(source.id)).toBe(-8884879n);
    const expenses = await prisma.transaction.findMany({ where: { accountId: source.id }, orderBy: { amountMinor: 'asc' } });
    expect(expenses.map(row => [row.type, row.amountMinor])).toEqual([['expense', -7884879n], ['expense', -1000000n]]);
    expect((await request('POST', `/loans/${loan.id}/payments`, body)).status).toBe(200);
    expect(await balance(source.id)).toBe(-8884879n);
    expect((await request('POST', `/loans/${loan.id}/payments`, { ...body, amountMinor: '1' })).status).toBe(409);
    const list = await request('GET', `/loans/${loan.id}/payments`);
    expect(list.body.items).toHaveLength(1);
    expect(list.body.items[0]).toMatchObject({ principalMinor: '7884879', interestMinor: '1000000', totalMinor: '8884879' });
  });

  it('pays with an explicit split, requires a category per non-zero part, uses the linked wallet', async () => {
    const source = await wallet();
    const loan = await createLoan({ accountId: source.id });
    const principalCategory = await category();
    const missing = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '1000', paidOn: '2026-12-01', principalMinor: '1000', interestMinor: '0',
    });
    expect(missing.status).toBe(400);
    const lone = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '1000', paidOn: '2026-12-01', principalMinor: '1000',
      principalCategoryId: principalCategory.id,
    });
    expect(lone.status).toBe(400);
    const ok = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '1000', paidOn: '2026-12-01', principalMinor: '1000', interestMinor: '0',
      principalCategoryId: principalCategory.id,
    });
    expect(ok.status).toBe(201);
    expect(ok.body.outstandingMinor).toBe('99999000');
    expect(await balance(source.id)).toBe(-1000n);
  });

  it('rejects overpayment and a wallet in another currency, and leaves nothing behind', async () => {
    const source = await wallet();
    await prisma.currency.upsert({ where: { code: 'USD' }, update: {}, create: { code: 'USD', minorDigits: 2, name: 'US Dollar' } });
    const usd = await wallet(owner, 'USD');
    const loan = await createLoan({ principalMinor: '1000', interestRateBps: 0, installmentMinor: null });
    const cat = await category();
    const over = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '1001', accountId: source.id, paidOn: '2026-12-01', principalCategoryId: cat.id,
    });
    expect(over.status).toBe(422);
    expect(over.body.error.code).toBe('LOAN_OVERPAYMENT');
    const wrong = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '10', accountId: usd.id, paidOn: '2026-12-01', principalCategoryId: cat.id,
    });
    expect(wrong.status).toBe(400);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    expect((await request('GET', `/loans/${loan.id}`)).body.outstandingMinor).toBe('1000');
  });

  it('clears the loan: paid_off, no next due date, schedule empty', async () => {
    const source = await wallet();
    const loan = await createLoan({ principalMinor: '1000', interestRateBps: 0, installmentMinor: null });
    const cat = await category();
    const paid = await request('POST', `/loans/${loan.id}/payments`, {
      clientId: randomUUID(), amountMinor: '1000', accountId: source.id, paidOn: '2026-12-01', principalCategoryId: cat.id,
    });
    expect(paid.body).toMatchObject({ outstandingMinor: '0', percentBps: 10000, status: 'paid_off', nextDueDate: null });
    const schedule = await request('GET', `/loans/${loan.id}/schedule`);
    expect(schedule.body.items).toEqual([]);
  });

  it('schedule sums principal to the outstanding and shows assumptions', async () => {
    const loan = await createLoan();
    const res = await request('GET', `/loans/${loan.id}/schedule`);
    expect(res.status).toBe(200);
    expect(res.body.assumption).toMatchObject({ outstandingMinor: '100000000', interestRateBps: 1200, frequency: 'monthly' });
    expect(res.body.items).toHaveLength(12);
    expect(res.body.items[0]).toMatchObject({ index: 1, interestMinor: '1000000' });
    const principal = res.body.items.reduce((sum: bigint, row: { principalMinor: string }) => sum + BigInt(row.principalMinor), 0n);
    expect(principal).toBe(100000000n);
  });

  it('summarises per currency over active loans only', async () => {
    const source = await wallet();
    const a = await createLoan({ principalMinor: '1000', interestRateBps: 0, installmentMinor: null });
    await createLoan({ principalMinor: '3000', interestRateBps: 0, installmentMinor: null });
    const cat = await category();
    await request('POST', `/loans/${a.id}/payments`, {
      clientId: randomUUID(), amountMinor: '400', accountId: source.id, paidOn: '2026-12-01', principalCategoryId: cat.id,
    });
    const summary = await request('GET', '/loans/summary');
    expect(summary.body.items).toEqual([{
      currencyCode: 'VND', loanCount: 2, principalMinor: '4000', paidMinor: '400', outstandingMinor: '3600', expectedInterestMinor: '0',
    }]);
    const current = (await request('GET', `/loans/${a.id}`)).body;
    expect((await request('DELETE', `/loans/${a.id}?version=${current.version}`)).status).toBe(204);
    expect((await request('GET', '/loans/summary')).body.items[0].loanCount).toBe(1);
  });

  it('adjusts with audit, edits with optimistic version, archives, and hides other users', async () => {
    const loan = await createLoan();
    const adjusted = await request('POST', `/loans/${loan.id}/adjust`, { outstandingMinor: '90000000', version: loan.version });
    expect(adjusted.status).toBe(200);
    expect(adjusted.body.outstandingMinor).toBe('90000000');
    expect(await prisma.auditEvent.count({ where: { action: 'loan.adjust', actorId: owner } })).toBe(1);
    expect((await request('POST', `/loans/${loan.id}/adjust`, { outstandingMinor: '1', version: loan.version })).status).toBe(409);
    expect((await request('POST', `/loans/${loan.id}/adjust`, { outstandingMinor: '90000000', version: adjusted.body.version })).status).toBe(400);
    const patched = await request('PATCH', `/loans/${loan.id}`, { version: adjusted.body.version, name: 'Đã đổi', interestRateBps: 1000 });
    expect(patched.body).toMatchObject({ name: 'Đã đổi', interestRateBps: 1000 });
    const other = await user();
    expect((await request('GET', `/loans/${loan.id}`, undefined, other.bearer)).status).toBe(404);
    expect((await request('DELETE', `/loans/${loan.id}?version=${patched.body.version}`)).status).toBe(204);
    expect((await request('GET', '/loans')).body.items).toHaveLength(0);
    expect((await request('GET', '/loans?includeArchived=true')).body.items).toHaveLength(1);
  });
});
