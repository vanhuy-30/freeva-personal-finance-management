import { TransactionModule } from '../src/modules/transactions/transaction.module';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { BudgetModule } from '../src/modules/budgets/budget.module';
import { ReportModule } from '../src/modules/reports/report.module';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;


describe('BE-P3-008 refunds HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let token: string;
  let otherToken: string;
  const fixtureUsers: string[] = [];
  const stream = new Writable({ write(_chunk, _encoding, callback) { callback(); } });

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{ serializers: { req: httpRequestSerializer }, redact: pinoRedactOptions }, stream] }),
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule, BudgetModule,
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
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) } });
    return { id, bearer };
  }
  beforeEach(async () => {
    const first = await user(); const second = await user();
    owner = first.id; token = first.bearer; otherToken = second.bearer;
  });
  afterAll(async () => {
    if (prisma) {
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.budget.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  async function call(method: string, path: string, body?: object, bearer = token, key?: string) {
    const res = await fetch(`${base}/api${path}`, {
      method,
      headers: { Authorization: `Bearer ${bearer}`, ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(key ? { 'Idempotency-Key': key } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }
  const wallet = (initial = 1000000n, currencyCode = 'VND') => prisma.financialAccount.create({
    data: { userId: owner, clientId: randomUUID(), name: 'Refund wallet', type: 'cash', currencyCode, initialBalanceMinor: initial } });
  const balance = async (id: string) => ((await call('GET', `/v1/financial-accounts/${id}`)).body as { balanceMinor: string }).balanceMinor;
  const category = () => prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Mua sắm', kind: 'expense' } });
  async function expense(accountId: string, categoryId: string, amount: bigint, occurredOn: string) {
    const clientId = randomUUID();
    const res = await call('POST', '/v1/transactions', { type: 'expense', occurredOn, categoryId,
      legs: [{ clientId, accountId, currencyCode: 'VND', amountMinor: (-amount).toString() }] }, token, clientId);
    expect(res.status).toBe(201);
    return res.body.legs[0] as { id: string; version: number };
  }
  const refund = (originalId: string, accountId: string, amount: string, extra: object = {}, clientId: string = randomUUID(), bearer = token) =>
    call('POST', `/v1/transactions/${originalId}/refunds`, { clientId, accountId, amountMinor: amount, ...extra }, bearer, clientId);
  const cashflow = async (on: string) => (await call('GET', `/v1/reports/cashflow?period=month&on=${on}`)).body;

  it('creates a one-leg refund into a wallet, same category, and replays on retry', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 500000n, '2026-10-05');
    expect(await balance(account.id)).toBe('500000');
    const id = randomUUID();
    const first = await refund(original.id, account.id, '200000', { occurredOn: '2026-10-20', notes: 'Trả hàng' }, id);
    expect(first.status).toBe(201);
    expect(first.body.legs).toHaveLength(1);
    expect(first.body.legs[0]).toMatchObject({ type: 'refund', amountMinor: '200000', categoryId: cat.id, refundOfId: original.id, occurredOn: '2026-10-20' });
    expect(await balance(account.id)).toBe('700000');
    const retry = await refund(original.id, account.id, '200000', { occurredOn: '2026-10-20', notes: 'Trả hàng' }, id);
    expect(retry.status).toBe(200);
    expect(retry.body.legs[0].id).toBe(first.body.legs[0].id);
    expect(await prisma.transaction.count({ where: { userId: owner, type: 'refund' } })).toBe(1);
    expect(await balance(account.id)).toBe('700000');
  });

  it('refunds into a different wallet and refuses a different currency', async () => {
    await prisma.currency.upsert({ where: { code: 'USD' }, update: {}, create: { code: 'USD', name: 'US Dollar', minorDigits: 2 } });
    const spend = await wallet(); const other = await wallet(0n); const usd = await wallet(0n, 'USD');
    const original = await expense(spend.id, (await category()).id, 300000n, '2026-10-05');
    expect((await refund(original.id, other.id, '100000')).status).toBe(201);
    expect(await balance(other.id)).toBe('100000');
    expect(await balance(spend.id)).toBe('700000');
    expect((await refund(original.id, usd.id, '100000')).status).toBe(400);
  });

  it('refuses to refund more than the expense in total, partial refunds add up, and a replay with other data conflicts', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 500000n, '2026-10-05');
    expect((await refund(original.id, account.id, '300000')).status).toBe(201);
    const over = await refund(original.id, account.id, '200001');
    expect(over).toMatchObject({ status: 409, body: { error: { code: 'REFUND_EXCEEDS_ORIGINAL' } } });
    expect((await refund(original.id, account.id, '200000')).status).toBe(201);
    expect((await refund(original.id, account.id, '1')).status).toBe(409);
    expect(await balance(account.id)).toBe('1000000');
    const id = randomUUID();
    const other = await expense(account.id, cat.id, 100000n, '2026-10-06');
    expect((await refund(other.id, account.id, '1000', {}, id)).status).toBe(201);
    expect((await refund(other.id, account.id, '2000', {}, id)).status).toBe(409);
    expect((await refund(randomUUID(), account.id, '1000')).status).toBe(404);
    expect((await refund(other.id, account.id, '0')).status).toBe(400);
    expect((await refund(other.id, account.id, '1000', {}, randomUUID(), otherToken)).status).toBe(404);
  });

  it('keeps two parallel refunds from passing the original amount', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 500000n, '2026-10-05');
    const results = await Promise.all([refund(original.id, account.id, '300000'), refund(original.id, account.id, '300000')]);
    expect(results.map(result => result.status).sort()).toEqual([201, 409]);
    expect(await balance(account.id)).toBe('800000');
  });

  it('only refunds an active expense', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 100000n, '2026-10-05');
    const income = randomUUID();
    const inc = await call('POST', '/v1/transactions', { type: 'income', occurredOn: '2026-10-05',
      legs: [{ clientId: income, accountId: account.id, currencyCode: 'VND', amountMinor: '50000' }] }, token, income);
    expect((await refund(inc.body.legs[0].id, account.id, '1000')).status).toBe(409);
    expect((await call('DELETE', `/v1/transactions/${original.id}?version=${original.version}`)).status).toBe(204);
    expect((await refund(original.id, account.id, '1000')).status).toBe(409);
    expect((await call('POST', '/v1/transactions', { type: 'refund', occurredOn: '2026-10-05', categoryId: cat.id,
      legs: [{ clientId: income, accountId: account.id, currencyCode: 'VND', amountMinor: '1' }] }, token, income)).status).toBe(400);
  });

  it('nets the refund out of the original month, not income, and leaves savings rate on net spend', async () => {
    const account = await wallet(0n); const cat = await category();
    const salary = randomUUID();
    await call('POST', '/v1/transactions', { type: 'income', occurredOn: '2026-10-02',
      legs: [{ clientId: salary, accountId: account.id, currencyCode: 'VND', amountMinor: '10000000' }] }, token, salary);
    const original = await expense(account.id, cat.id, 2000000n, '2026-10-10');
    const before = await cashflow('2026-10-15');
    expect(before.totals[0]).toMatchObject({ incomeMinor: '10000000', expenseMinor: '-2000000' });
    // Refund arrives next month: October still shrinks, November shows nothing.
    await refund(original.id, account.id, '500000', { occurredOn: '2026-11-02' });
    const october = await cashflow('2026-10-15');
    expect(october.totals[0]).toMatchObject({ incomeMinor: '10000000', expenseMinor: '-1500000', netMinor: '8500000' });
    expect(october.byCategory.find((item: { categoryId: string }) => item.categoryId === cat.id))
      .toMatchObject({ expenseMinor: '-1500000', transactionCount: 1 });
    expect(october.totals[0].savingsRateBps).toBe(8500);
    expect((await cashflow('2026-11-15')).totals).toEqual([]);
    const row = october.byAccount.find((item: { accountId: string }) => item.accountId === account.id);
    expect(row).toMatchObject({ expenseMinor: '-2000000', refundMinor: '0' });
    expect((await cashflow('2026-11-15')).byAccount.find((item: { accountId: string }) => item.accountId === account.id)).toMatchObject({ refundMinor: '500000', netMinor: '500000' });
    expect(await balance(account.id)).toBe('8500000');
    const list = (await call('GET', `/v1/transactions?accountId=${account.id}&type=refund`)).body;
    expect(list.total).toBe(1);
    expect(list.summary.totals[0]).toMatchObject({ refundMinor: '500000', incomeMinor: '0' });
  });

  it('reduces budget spend in the period of the original expense', async () => {
    const account = await wallet(0n); const cat = await category();
    const original = await expense(account.id, cat.id, 2000000n, '2026-10-10');
    const put = await call('PUT', '/v1/budgets/current', { limitMinor: '5000000', categories: [{ categoryId: cat.id, limitMinor: '3000000' }] });
    expect(put.status).toBe(200);
    expect((await call('GET', '/v1/budgets/current?on=2026-10-15')).body.budget).toMatchObject({ spentMinor: '2000000' });
    await refund(original.id, account.id, '700000', { occurredOn: '2026-11-04' });
    const october = (await call('GET', '/v1/budgets/current?on=2026-10-15')).body.budget;
    expect(october).toMatchObject({ spentMinor: '1300000' });
    expect(october.categories[0]).toMatchObject({ spentMinor: '1300000' });
    expect((await call('GET', '/v1/budgets/current?on=2026-11-15')).body.budget).toMatchObject({ spentMinor: '0' });
  });

  it('asks what to do with refunds when the original expense is deleted', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 400000n, '2026-10-05');
    await refund(original.id, account.id, '100000');
    const blocked = await call('DELETE', `/v1/transactions/${original.id}?version=${original.version}`);
    expect(blocked).toMatchObject({ status: 409, body: { error: { code: 'REFUND_EXISTS' } } });
    expect(await balance(account.id)).toBe('700000');
    const cascade = await call('DELETE', `/v1/transactions/${original.id}?version=${original.version}&refunds=cascade`);
    expect(cascade.status).toBe(204);
    expect(await balance(account.id)).toBe('1000000');
    expect(await prisma.transaction.count({ where: { userId: owner, type: 'refund', deletedAt: null } })).toBe(0);
  });

  it('turns refunds into plain income when the original is deleted with refunds=keep', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 400000n, '2026-10-05');
    await refund(original.id, account.id, '100000');
    expect((await call('DELETE', `/v1/transactions/${original.id}?version=${original.version}&refunds=keep`)).status).toBe(204);
    expect(await balance(account.id)).toBe('1100000');
    const kept = await prisma.transaction.findFirstOrThrow({ where: { userId: owner, amountMinor: 100000n } });
    expect(kept).toMatchObject({ type: 'income', refundOfId: null, categoryId: null, deletedAt: null });
  });

  it('guards edits of the original and of a refund against the cap', async () => {
    const account = await wallet(); const cat = await category();
    const original = await expense(account.id, cat.id, 400000n, '2026-10-05');
    const created = (await refund(original.id, account.id, '300000')).body.legs[0] as { id: string; version: number };
    const shrink = await call('PATCH', `/v1/transactions/${original.id}`, { version: original.version,
      legs: [{ clientId: (await prisma.transaction.findUniqueOrThrow({ where: { id: original.id } })).clientId, accountId: account.id, currencyCode: 'VND', amountMinor: '-200000' }] });
    expect(shrink).toMatchObject({ status: 409, body: { error: { code: 'REFUND_EXCEEDS_ORIGINAL' } } });
    const grow = await call('PATCH', `/v1/transactions/${created.id}`, { version: created.version,
      legs: [{ clientId: (await prisma.transaction.findUniqueOrThrow({ where: { id: created.id } })).clientId, accountId: account.id, currencyCode: 'VND', amountMinor: '400001' }] });
    expect(grow.status).toBe(409);
    expect((await call('PATCH', `/v1/transactions/${created.id}`, { version: created.version, categoryId: cat.id })).status).toBe(400);
    // Deleting a refund frees the room again.
    expect((await call('DELETE', `/v1/transactions/${created.id}?version=${created.version}`)).status).toBe(204);
    expect((await refund(original.id, account.id, '400000')).status).toBe(201);
  });
});
