import { TransactionModule } from '../src/modules/transactions/transaction.module';
import { TransactionImportModule } from '../src/modules/transaction-import/transaction-import.module';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;


describe('BE-P3-011 transactions CSV import HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, TransactionImportModule,
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
      await prisma.importBatch.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  const call = (method: string, path: string, body?: object, bearer = token) => fetch(`${base}/api${path}`, {
    method, headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
  const wallet = (name: string, userId = owner) => prisma.financialAccount.create({
    data: { userId, clientId: randomUUID(), name, type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n } });
  const category = (name: string, kind: 'expense' | 'income') => prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name, kind } });
  const header = 'date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n';

  async function setup() {
    const cash = await wallet('Tiền mặt'); const bank = await wallet('Ngân hàng');
    const food = await category('Ăn uống', 'expense'); const pay = await category('Lương', 'income');
    const text = `${header}2026-10-05,08:30,expense,-45000,VND,Tiền mặt,Ăn uống,Phở,sáng,,\r\n2026-10-06,,income,20000000,VND,Ngân hàng,Lương,,tháng 10,,\r\n2026-10-07,,transfer,-100000,VND,Tiền mặt,,,rút,,\r\n2026-10-07,,transfer,100000,VND,Ngân hàng,,,rút,,\r\n2026-10-08,,expense,-1,VND,Ví lạ,Ăn uống,,,,\r\n`;
    return { cash, bank, food, pay, text };
  }

  it('previews without writing, then commits once and replays by batchClientId', async () => {
    const { cash, bank, text } = await setup();
    const preview = await call('POST', '/v1/transactions/import/preview', { text });
    expect(preview.status).toBe(200);
    const body = await preview.json();
    expect(body.preset).toBe('freeva');
    expect(body.summary).toEqual({ rowCount: 5, ready: 3, duplicate: 0, invalid: 1 });
    expect(body.unmapped.wallets).toEqual(['Ví lạ']);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);

    const batchClientId = randomUUID();
    const commit = await call('POST', '/v1/transactions/import', { text, batchClientId });
    expect(commit.status).toBe(201);
    const done = await commit.json();
    expect(done.batch).toMatchObject({ rowCount: 5, createdCount: 3, duplicateCount: 0, invalidCount: 1, remainingCount: 4 });
    expect(done.rows.map((row: { status: string }) => row.status)).toEqual(['created', 'created', 'created', 'invalid']);
    const legs = await prisma.transaction.findMany({ where: { userId: owner }, orderBy: [{ occurredOn: 'asc' }, { amountMinor: 'asc' }] });
    expect(legs).toHaveLength(4);
    expect(legs.every(leg => leg.importBatchId === done.batch.id)).toBe(true);
    expect(legs.filter(leg => leg.type === 'transfer').map(leg => [leg.accountId, leg.amountMinor])).toEqual([[cash.id, -100000n], [bank.id, 100000n]]);
    expect(legs[0].occurredTime).toBe('08:30');

    const replay = await call('POST', '/v1/transactions/import', { text, batchClientId });
    expect(replay.status).toBe(200);
    expect((await replay.json()).rows).toBeNull();
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(4);
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'transaction_import.create' } })).toBe(1);
  });

  it('flags rows already in the ledger and only writes them when asked', async () => {
    const { text } = await setup();
    await call('POST', '/v1/transactions/import', { text, batchClientId: randomUUID() });
    const again = await (await call('POST', '/v1/transactions/import/preview', { text })).json();
    expect(again.summary).toMatchObject({ duplicate: 3, ready: 0, invalid: 1 });
    const skipped = await (await call('POST', '/v1/transactions/import', { text, batchClientId: randomUUID() })).json();
    expect(skipped.batch).toMatchObject({ createdCount: 0, duplicateCount: 3 });
    expect(skipped.rows.map((row: { status: string }) => row.status)).toEqual(['skipped_duplicate', 'skipped_duplicate', 'skipped_duplicate', 'invalid']);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(4);
    const forced = await (await call('POST', '/v1/transactions/import', { text, batchClientId: randomUUID(), includeDuplicates: true })).json();
    expect(forced.batch.createdCount).toBe(3);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(8);
  });

  it('maps unknown wallets and undoes the whole batch except edited rows', async () => {
    const { cash, text } = await setup();
    const res = await call('POST', '/v1/transactions/import', { text, batchClientId: randomUUID(), walletMap: { 'Ví lạ': cash.id } });
    const done = await res.json();
    expect(done.batch.createdCount).toBe(4);
    const edited = await prisma.transaction.findFirstOrThrow({ where: { userId: owner, importBatchId: done.batch.id, type: 'income' } });
    const patch = await call('PATCH', `/v1/transactions/${edited.id}`, { version: 1, notes: 'đã sửa' });
    expect(patch.status).toBe(200);
    const undo = await (await call('POST', `/v1/transactions/import/${done.batch.id}/undo`)).json();
    expect(undo.undoneCount).toBe(3);
    expect(undo.skipped).toEqual([{ transactionId: edited.id, reason: 'modified' }]);
    expect(undo.batch.undoneAt).not.toBeNull();
    expect(await prisma.transaction.count({ where: { userId: owner, deletedAt: null } })).toBe(1);
    const again = await (await call('POST', `/v1/transactions/import/${done.batch.id}/undo`)).json();
    expect(again.undoneCount).toBe(0);
    expect((await (await call('GET', `/v1/transactions/import/${done.batch.id}`)).json()).remainingCount).toBe(1);
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'transaction_import.undo' } })).toBe(2);
  });

  it('isolates users and rejects bad requests', async () => {
    const { text } = await setup();
    const done = await (await call('POST', '/v1/transactions/import', { text, batchClientId: randomUUID() })).json();
    expect((await call('GET', `/v1/transactions/import/${done.batch.id}`, undefined, otherToken)).status).toBe(404);
    expect((await call('POST', `/v1/transactions/import/${done.batch.id}/undo`, undefined, otherToken)).status).toBe(404);
    const stranger = await (await call('POST', '/v1/transactions/import/preview', { text }, otherToken)).json();
    expect(stranger.summary.ready).toBe(0);
    expect((await call('POST', '/v1/transactions/import/preview', { text: 'foo,bar\r\n1,2\r\n' })).status).toBe(400);
    expect((await call('POST', '/v1/transactions/import/preview', { text: 'a,"b' })).status).toBe(400);
    expect((await call('POST', '/v1/transactions/import', { text })).status).toBe(400);
    expect((await call('POST', '/v1/transactions/import/preview', { text, walletMap: { x: 'nope' } })).status).toBe(400);
    expect((await fetch(`${base}/api/v1/transactions/import/preview`, { method: 'POST' })).status).toBe(401);
  });
});
