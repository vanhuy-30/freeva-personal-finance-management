import { TransactionModule } from '../src/modules/transactions/transaction.module';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
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


describe('BE-P3-005 wallet reconciliation HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, ReportModule,
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
  const reconcile = (accountId: string, actual: string, extra: object = {}, clientId: string = randomUUID(), bearer = token) =>
    call('POST', `/v1/financial-accounts/${accountId}/reconcile`, { clientId, actualBalanceMinor: actual, ...extra }, bearer, clientId);
  const wallet = (type: 'cash' | 'credit' = 'cash', initial = 0n) => prisma.financialAccount.create({
    data: { userId: owner, clientId: randomUUID(), name: 'Reconcile wallet', type, currencyCode: 'VND', initialBalanceMinor: initial } });
  const balance = async (id: string) => ((await call('GET', `/v1/financial-accounts/${id}`)).body as { balanceMinor: string }).balanceMinor;

  it('creates a one-leg adjustment that sets the balance and replays on retry', async () => {
    const account = await wallet('cash', 1000000n);
    const id = randomUUID();
    const first = await reconcile(account.id, '900000', { occurredOn: '2026-10-06', notes: 'Kiểm tra ví' }, id);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({ currentBalanceMinor: '1000000', targetBalanceMinor: '900000', deltaMinor: '-100000' });
    expect(first.body.transaction.legs).toHaveLength(1);
    expect(first.body.transaction.legs[0]).toMatchObject({ type: 'adjustment', categoryId: null, merchant: null, occurredOn: '2026-10-06' });
    expect(await balance(account.id)).toBe('900000');
    const retry = await reconcile(account.id, '900000', { occurredOn: '2026-10-06', notes: 'Kiểm tra ví' }, id);
    expect(retry.status).toBe(200);
    expect(retry.body.transaction.legs[0].id).toBe(first.body.transaction.legs[0].id);
    expect(await prisma.transaction.count({ where: { userId: owner, type: 'adjustment' } })).toBe(1);
    expect(await balance(account.id)).toBe('900000');
  });

  it('returns delta without writing for zero difference and dry run', async () => {
    const account = await wallet('cash', 500000n);
    const same = await reconcile(account.id, '500000');
    expect(same).toMatchObject({ status: 200, body: { deltaMinor: '0', transaction: null } });
    const dry = await reconcile(account.id, '700000', { dryRun: true });
    expect(dry).toMatchObject({ status: 200, body: { currentBalanceMinor: '500000', deltaMinor: '200000', transaction: null } });
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
  });

  it('reconciles a credit card against debt', async () => {
    const card = await wallet('credit', 0n);
    const res = await reconcile(card.id, '3000000');
    expect(res.status).toBe(201);
    expect(res.body).toMatchObject({ targetBalanceMinor: '-3000000', deltaMinor: '-3000000' });
    expect(await balance(card.id)).toBe('-3000000');
    const lower = await reconcile(card.id, '2000000');
    expect(lower.body.deltaMinor).toBe('1000000');
    expect(await balance(card.id)).toBe('-2000000');
  });

  it('does not change period income, expense or savings rate; shows as adjustmentMinor and in the wallet list', async () => {
    const account = await wallet('cash', 0n);
    const income = randomUUID();
    await prisma.transaction.create({ data: { userId: owner, clientId: income, accountId: account.id, currencyCode: 'VND', type: 'income', amountMinor: 1000000n, occurredOn: new Date('2026-10-02') } });
    const before = (await call('GET', '/v1/reports/cashflow?period=month&on=2026-10-08')).body;
    await reconcile(account.id, '1300000', { occurredOn: '2026-10-03' });
    const after = (await call('GET', '/v1/reports/cashflow?period=month&on=2026-10-08')).body;
    expect(after.totals).toEqual(before.totals);
    expect(after.byCategory).toEqual(before.byCategory);
    const row = after.byAccount.find((item: { accountId: string }) => item.accountId === account.id);
    expect(row).toMatchObject({ incomeMinor: '1000000', expenseMinor: '0', adjustmentMinor: '300000', netMinor: '1300000' });
    const list = (await call('GET', `/v1/transactions?accountId=${account.id}`)).body;
    expect(list.items.map((item: { type: string }) => item.type)).toContain('adjustment');
    expect(list.summary.totals[0]).toMatchObject({ incomeMinor: '1000000', expenseMinor: '0', adjustmentMinor: '300000' });
    expect((await call('GET', `/v1/transactions?accountId=${account.id}&type=adjustment`)).body.total).toBe(1);
  });

  it('edits and deletes an adjustment like a transaction and refuses category/FX, direct create and other owners', async () => {
    const account = await wallet('cash', 0n);
    const created = (await reconcile(account.id, '100000')).body.transaction.legs[0];
    const edited = await call('PATCH', `/v1/transactions/${created.id}`, { version: 1, legs: [{ clientId: created.clientId, accountId: account.id, currencyCode: 'VND', amountMinor: '80000' }] });
    expect(edited.status).toBe(200);
    expect(await balance(account.id)).toBe('80000');
    const category = await prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Any', kind: 'both' } });
    expect((await call('PATCH', `/v1/transactions/${created.id}`, { version: 2, categoryId: category.id })).status).toBe(400);
    expect((await call('DELETE', `/v1/transactions/${created.id}?version=2`)).status).toBe(204);
    expect(await balance(account.id)).toBe('0');
    const direct = randomUUID();
    expect((await call('POST', '/v1/transactions', { type: 'adjustment', occurredOn: '2026-10-05',
      legs: [{ clientId: direct, accountId: account.id, currencyCode: 'VND', amountMinor: '5' }] }, token, direct)).status).toBe(400);
    expect((await reconcile(account.id, '1', {}, randomUUID(), otherToken)).status).toBe(404);
    expect((await call('POST', `/v1/financial-accounts/${account.id}/reconcile`, { clientId: randomUUID(), actualBalanceMinor: '1' }, token, randomUUID())).status).toBe(400);
  });
});
