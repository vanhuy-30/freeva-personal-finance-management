import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';
import { SyncModule } from '../src/modules/sync/sync.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-009 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let other: string;
  let token: string;
  let logs = '';
  const fixtureUsers: string[] = [];
  const stream = new Writable({ write(chunk, _encoding, callback) { logs += chunk.toString(); callback(); } });
  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{ serializers: { req: httpRequestSerializer }, redact: pinoRedactOptions }, stream] }),
        PrismaModule, SyncModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
    await prisma.schemaMeta.upsert({ where: { id: 1 }, create: { id: 1, version: 1 }, update: { version: 1 } });
  });
  async function user() {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) } });
    return { id, bearer };
  }
  beforeEach(async () => {
    const first = await user(); const second = await user();
    owner = first.id; token = first.bearer; other = second.id;
    logs = '';
    await prisma.schemaMeta.update({ where: { id: 1 }, data: { version: 1 } });
  });
  afterAll(async () => {
    if (prisma) {
      await prisma.schemaMeta.upsert({ where: { id: 1 }, create: { id: 1, version: 1 }, update: { version: 1 } });
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  async function account(userId = owner) {
    return prisma.financialAccount.create({ data: { userId, clientId: randomUUID(), name: 'Private test wallet', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n } });
  }
  function operation(action: string, body: object, extra: object = {}) {
    return { opId: randomUUID(), action, ...extra, ...(action === 'delete' ? {} : { body }) };
  }
  async function income(amount = '135792468', userId = owner) {
    const wallet = await account(userId);
    return { type: 'income', occurredOn: '2026-10-09', notes: 'sync-private-note', legs: [{ clientId: randomUUID(), accountId: wallet.id, currencyCode: 'VND', amountMinor: amount }] };
  }
  async function sync(operations: object[], bearer = token, schemaVersion = 1) {
    const res = await fetch(`${base}/api/v1/sync`, {
      method: 'POST', headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: JSON.stringify({ schemaVersion, operations }),
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) as {
      schemaVersion?: number;
      error?: { code: string; details: unknown[] };
      results?: { opId: string; status: string; review: boolean; duplicates: { id: string; clientId: string }[]; transaction: { legs: { id: string; amountMinor: string; clientId: string }[] } | null; error: { code: string; details: unknown[] } | null }[];
    } : undefined };
  }
  it('replays one row, keeps a conflicting amount, and still applies the next operation', async () => {
    const body = await income();
    const created = await sync([operation('create', body)]);
    expect(created.status).toBe(200);
    expect(created.body?.results?.[0]).toMatchObject({ status: 'applied', review: false, duplicates: [] });
    expect(created.body?.results?.[0].transaction?.legs[0].amountMinor).toBe('135792468');
    const replay = await sync([operation('create', body)]);
    expect(replay.body?.results?.[0]).toMatchObject({ status: 'replayed', duplicates: [] });
    expect(await prisma.transaction.count({ where: { userId: owner, clientId: body.legs[0].clientId } })).toBe(1);
    const next = await income('24681357');
    const conflicted = await sync([
      operation('create', { ...body, legs: [{ ...body.legs[0], amountMinor: '135792469' }] }),
      operation('create', next),
    ]);
    expect(conflicted.body?.results?.map(result => result.status)).toEqual(['conflict', 'applied']);
    expect(conflicted.body?.results?.[0]).toMatchObject({ review: true, transaction: { legs: [{ amountMinor: '135792468' }] } });
    expect(await prisma.transaction.findFirstOrThrow({ where: { clientId: body.legs[0].clientId } })).toMatchObject({ amountMinor: 135792468n });
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(2);
    expect(logs).not.toContain('135792468');
    expect(logs).not.toContain('sync-private-note');
  });
  it('hints at a recent duplicate for the owner and ignores another user or an older row', async () => {
    const first = await income();
    const created = await sync([operation('create', first)]);
    const firstId = created.body?.results?.[0].transaction?.legs[0].id;
    const duplicate = await income();
    duplicate.legs[0].accountId = first.legs[0].accountId;
    const hinted = await sync([operation('create', duplicate)]);
    expect(hinted.body?.results?.[0].status).toBe('applied');
    expect(hinted.body?.results?.[0].duplicates).toEqual([{ id: firstId, clientId: first.legs[0].clientId }]);
    expect(await prisma.transaction.count({ where: { userId: owner, amountMinor: 135792468n } })).toBe(2);
    const foreignClient = randomUUID();
    await prisma.transaction.create({ data: { userId: other, clientId: foreignClient, type: 'income', amountMinor: 135792468n, currencyCode: 'VND', occurredOn: new Date('2026-10-09'), accountId: first.legs[0].accountId } });
    const again = await income();
    again.legs[0].accountId = first.legs[0].accountId;
    const isolated = await sync([operation('create', again)]);
    expect(isolated.body?.results?.[0].duplicates.map(item => item.clientId)).toEqual(expect.arrayContaining([first.legs[0].clientId, duplicate.legs[0].clientId]));
    expect(isolated.body?.results?.[0].duplicates.map(item => item.clientId)).not.toContain(foreignClient);
    await prisma.transaction.updateMany({ where: { userId: owner }, data: { createdAt: new Date(Date.now() - 11 * 60 * 1000) } });
    const fresh = await income();
    fresh.legs[0].accountId = first.legs[0].accountId;
    const stale = await sync([operation('create', fresh)]);
    expect(stale.body?.results?.[0].duplicates).toEqual([]);
  });
  it('rejects a bad queue, an anonymous caller and a schema mismatch before writing', async () => {
    const body = await income();
    expect((await sync([], '')).status).toBe(401);
    expect((await sync([])).status).toBe(400);
    const opId = randomUUID();
    expect((await sync([{ ...operation('create', body), opId }, { ...operation('create', body), opId }])).status).toBe(400);
    expect((await sync(Array.from({ length: 51 }, () => operation('create', body)))).status).toBe(400);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    await prisma.schemaMeta.update({ where: { id: 1 }, data: { version: 2 } });
    const mismatch = await sync([operation('create', body)]);
    expect(mismatch.status).toBe(409);
    expect(mismatch.body).toMatchObject({ error: { code: 'SYNC_SCHEMA_MISMATCH', details: [] } });
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    await prisma.schemaMeta.delete({ where: { id: 1 } });
    try {
      const missing = await sync([operation('create', body)]);
      expect(missing.status).toBe(503);
      expect(missing.body).toMatchObject({ error: { code: 'SYNC_UNAVAILABLE', details: [] } });
      expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    } finally {
      await prisma.schemaMeta.upsert({ where: { id: 1 }, create: { id: 1, version: 1 }, update: { version: 1 } });
    }
  });
  it('updates and deletes with the current version and does not overwrite a stale amount', async () => {
    const body = await income();
    const created = await sync([operation('create', body)]);
    const id = created.body!.results![0].transaction!.legs[0].id;
    const updated = await sync([operation('update', { version: 1, notes: 'renamed' }, { id })]);
    expect(updated.body?.results?.[0]).toMatchObject({ status: 'applied', review: false });
    const stale = await sync([operation('update', { version: 1, legs: body.legs }, { id })]);
    expect(stale.body?.results?.[0]).toMatchObject({ status: 'conflict', review: false, transaction: { legs: [{ amountMinor: '135792468' }] } });
    const changed = await sync([operation('update', { version: 1, legs: [{ ...body.legs[0], amountMinor: '135792469' }] }, { id })]);
    expect(changed.body?.results?.[0]).toMatchObject({ status: 'conflict', review: true });
    expect((await prisma.transaction.findUniqueOrThrow({ where: { id } })).amountMinor).toBe(135792468n);
    const removed = await sync([operation('delete', {}, { id, version: 2 })]);
    expect(removed.body?.results?.[0]).toMatchObject({ status: 'applied', transaction: null, error: null });
    expect((await prisma.transaction.findUniqueOrThrow({ where: { id } })).deletedAt).not.toBeNull();
  });
});
