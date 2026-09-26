import { PrismaCategoryRepository } from '../src/modules/categories/infrastructure/prisma-category.repository';
import { CategoryModule } from '../src/modules/categories/category.module';
import { Prisma } from '@prisma/client';
import { TransactionModule } from '../src/modules/transactions/transaction.module';
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

describe('BE-P1-006 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let other: string;
  let token: string;
  let otherToken: string;
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
        PrismaModule, FinancialAccountModule, TransactionModule, CategoryModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
    await prisma.currency.upsert({ where: { code: 'USD' }, create: { code: 'USD', minorDigits: 2, name: 'US Dollar' }, update: {} });
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
    owner = first.id; token = first.bearer; other = second.id; otherToken = second.bearer;
    logs = '';
  });
  afterAll(async () => {
    if (prisma) {
      await prisma.transactionTag.deleteMany({ where: { transaction: { userId: { in: fixtureUsers } } } });
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.fxQuote.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.tag.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  async function request(method = 'GET', path = '/categories', body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1${path}`, { method,
      headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
        ...(path === '/transactions' && method === 'POST' ? { 'Idempotency-Key': (body as { legs: { clientId: string }[] }).legs[0].clientId } : {}) },
      body: body ? JSON.stringify(body) : undefined });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }
  async function category(name = 'Private category', parentId?: string, bearer = token) {
    const result = await request('POST', '/categories', { clientId: randomUUID(), name, parentId }, bearer);
    expect(result.status).toBe(201); return result.body;
  }
  async function expense(categoryId: string) {
    const wallet = await prisma.financialAccount.create({ data: { userId: owner, clientId: randomUUID(), name: 'Private wallet', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n } });
    return { type: 'expense', categoryId, occurredOn: '2026-09-25', notes: 'Private note', legs: [
      { clientId: randomUUID(), accountId: wallet.id, currencyCode: 'VND', amountMinor: '-9007199254740993' }] };
  }
  it('GET is read-only; bootstraps once concurrently and never recreates edited/deleted defaults', async () => {
    expect((await request()).body.total).toBe(0);
    expect((await prisma.user.findUniqueOrThrow({ where: { id: owner } })).categoriesInitializedAt).toBeNull();
    const custom = await category();
    const responses = await Promise.all([request('POST', '/categories/defaults'), request('POST', '/categories/defaults')]);
    expect(responses.map(r => r.status)).toEqual([204, 204]);
    const list = (await request()).body;
    expect(list.total).toBe(16); expect(list.items.filter((c: { isSystem: boolean }) => c.isSystem)).toHaveLength(15);
    expect(JSON.stringify(list)).not.toContain(owner);
    const defaults = list.items.filter((c: { id: string }) => c.id !== custom.id);
    expect((await request('DELETE', `/categories/${defaults[0].id}?version=1`)).status).toBe(204);
    expect((await request('PATCH', `/categories/${defaults[1].id}`, { version: 1, name: 'Renamed' })).status).toBe(200);
    expect((await request('POST', '/categories/defaults')).status).toBe(204);
    expect((await request()).body.total).toBe(15);
    expect((await request('GET', `/categories/${defaults[1].id}`)).body.name).toBe('Renamed');
    expect((await prisma.user.findUniqueOrThrow({ where: { id: owner } })).version).toBe(1);
  });
  it('enforces session, ownership, safe errors and no-store on every route', async () => {
    const c = await category();
    for (const [method, path, body] of [
      ['GET', '/categories', undefined], ['GET', '/categories/recent', undefined], ['GET', '/categories/options', undefined],
      ['POST', '/categories/defaults', undefined], ['POST', '/categories', { clientId: randomUUID(), name: 'x' }],
      ['GET', `/categories/${c.id}`, undefined], ['PATCH', `/categories/${c.id}`, { version: 1, name: 'x' }],
      ['DELETE', `/categories/${c.id}?version=1`, undefined],
    ] as const) expect((await request(method, path, body, '')).status).toBe(401);
    for (const [method, path, body] of [
      ['GET', `/categories/${c.id}`, undefined], ['PATCH', `/categories/${c.id}`, { version: 1, archived: true }],
      ['DELETE', `/categories/${c.id}?version=1`, undefined], ['GET', `/categories?parentId=${c.id}`, undefined],
    ] as const) expect((await request(method, path, body, otherToken)).status).toBe(404);
    expect((await request('POST', '/categories', { clientId: randomUUID(), name: 'x', parentId: c.id }, otherToken)).status).toBe(404);
    expect((await request('GET', '/categories', undefined, otherToken)).body.total).toBe(0);
    expect(logs).not.toContain('Private category'); expect(logs).not.toContain(token);
  });
  it('supports custom metadata, normalized replay, conflicts and concurrent create/update', async () => {
    const dto = { clientId: randomUUID(), name: ' Custom ', colorToken: 'color.brand.primary', iconToken: 'food' };
    const results = await Promise.all([request('POST', '/categories', dto), request('POST', '/categories', dto)]);
    expect(results.map(r => r.status).sort()).toEqual([200, 201]);
    const c = results[0].body;
    expect(c.name).toBe('Custom'); expect(c.isSystem).toBe(false);
    expect((await request('POST', '/categories', { ...dto, name: 'Changed' })).status).toBe(409);
    const changes = await Promise.all([request('PATCH', `/categories/${c.id}`, { version: 1, name: 'A' }), request('PATCH', `/categories/${c.id}`, { version: 1, name: 'B' })]);
    expect(changes.map(r => r.status).sort()).toEqual([200, 409]);
    for (const patch of [{ colorToken: '#5680E9' }, { iconToken: 'unknown' }, { name: ' ' }, { isSystem: true }, { userId: other }, { groupId: randomUUID() }]) {
      const result = await request('POST', '/categories', { clientId: randomUUID(), name: 'Private invalid name', ...patch });
      expect(result.status).toBe(400); expect(JSON.stringify(result.body)).not.toContain('Private invalid name');
    }
    expect((await request('GET', '/categories/options')).body.iconTokens).toContain('category');
  });
  it('enforces tree cycles, archive order, restore order and child deletion guard', async () => {
    const root = await category('Root'); const child = await category('Child', root.id); const leaf = await category('Leaf', child.id);
    expect((await request('PATCH', `/categories/${root.id}`, { version: 1, parentId: leaf.id })).status).toBe(400);
    expect((await request('PATCH', `/categories/${root.id}`, { version: 1, archived: true })).status).toBe(409);
    expect((await request('DELETE', `/categories/${root.id}?version=1`)).status).toBe(409);
    for (const c of [leaf, child, root]) expect((await request('PATCH', `/categories/${c.id}`, { version: 1, archived: true })).status).toBe(200);
    expect((await request('DELETE', `/categories/${root.id}?version=2`)).status).toBe(409);
    expect((await request('PATCH', `/categories/${leaf.id}`, { version: 2, archived: false })).status).toBe(409);
    expect((await request('POST', '/categories', { clientId: randomUUID(), name: 'New', parentId: root.id })).status).toBe(409);
    expect((await request('PATCH', `/categories/${leaf.id}`, { version: 2, parentId: null, archived: false })).status).toBe(200);
    expect((await request('GET', '/categories?status=archived&pageSize=1&page=2')).body.total).toBe(2);
    expect((await request('GET', '/categories?parentId=root&status=all')).body.total).toBe(2);
    expect((await request('GET', `/categories?parentId=${root.id}&status=all`)).body.items[0].id).toBe(child.id);
  });
  it('moves active/deleted transactions atomically, preserves balances/tags and invalidates old versions', async () => {
    const source = await category(), target = await category('Target');
    const input = await expense(source.id);
    const active = (await request('POST', '/transactions', input)).body.legs[0];
    const second = (await request('POST', '/transactions', { ...input, legs: [{ ...input.legs[0], clientId: randomUUID() }] })).body.legs[0];
    expect((await request('DELETE', `/transactions/${second.id}?version=1`)).status).toBe(204);
    const before = await prisma.transaction.findMany({ where: { userId: owner }, orderBy: { id: 'asc' } });
    const balance = (await request('GET', `/financial-accounts/${input.legs[0].accountId}`)).body.balanceMinor;
    expect((await request('DELETE', `/categories/${source.id}?version=1`)).status).toBe(409);
    expect((await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${source.id}`)).status).toBe(400);
    expect((await request('PATCH', `/categories/${target.id}`, { version: 1, archived: true })).status).toBe(200);
    expect((await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`)).status).toBe(409);
    expect((await request('PATCH', `/categories/${target.id}`, { version: 2, archived: false })).status).toBe(200);
    const foreign = await category('Other', undefined, otherToken);
    expect((await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${foreign.id}`)).status).toBe(404);
    const tag = await prisma.tag.create({ data: { userId: owner, clientId: randomUUID(), name: 'Private tag' } });
    await prisma.transactionTag.create({ data: { transactionId: active.id, tagId: tag.id } });
    expect((await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`)).status).toBe(204);
    const after = await prisma.transaction.findMany({ where: { userId: owner }, orderBy: { id: 'asc' } });
    after.forEach((row, i) => {
      expect(row.categoryId).toBe(target.id); expect(row.version).toBe(before[i].version + 1);
      expect({ ...row, categoryId: before[i].categoryId, version: before[i].version, updatedAt: before[i].updatedAt }).toEqual(before[i]);
    });
    expect(await prisma.transactionTag.count({ where: { transactionId: active.id } })).toBe(1);
    expect((await request('GET', `/financial-accounts/${input.legs[0].accountId}`)).body.balanceMinor).toBe(balance);
    expect((await request('PATCH', `/transactions/${active.id}`, { version: 1, notes: 'Stale' })).status).toBe(409);
    expect((await request('PATCH', `/transactions/${second.id}`, { version: 3, deleted: false })).status).toBe(200);
    expect((await request('GET', `/categories/${source.id}`)).status).toBe(404);
    expect(logs).not.toContain('Private note'); expect(logs).not.toContain('9007199254740993');
  });
  it('rolls back transfer on transaction version overflow', async () => {
    const source = await category(), target = await category('Target');
    const input = await expense(source.id);
    const tx = (await request('POST', '/transactions', input)).body.legs[0];
    await prisma.transaction.update({ where: { id: tx.id }, data: { version: 2147483647 } });
    expect((await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`)).status).toBe(409);
    expect((await prisma.transaction.findUniqueOrThrow({ where: { id: tx.id } })).categoryId).toBe(source.id);
    expect((await request('GET', `/categories/${source.id}`)).status).toBe(200);
  });
  it('recent excludes archived/deleted/foreign categories, deduplicates, orders by creation and limits to ten', async () => {
    const ids: string[] = [];
    for (let i = 0; i < 12; i++) {
      const c = await category(`C${i}`); ids.push(c.id);
      const input = await expense(c.id);
      const tx = (await request('POST', '/transactions', input)).body.legs[0];
      await prisma.transaction.update({ where: { id: tx.id }, data: { createdAt: new Date(Date.UTC(2026, 0, i + 1)) } });
    }
    expect((await request('GET', '/categories/recent')).body.items.map((c: { id: string }) => c.id)).toEqual(ids.slice(2).reverse());
    expect((await request('PATCH', `/categories/${ids[11]}`, { version: 1, archived: true })).status).toBe(200);
    await prisma.transaction.updateMany({ where: { userId: owner, categoryId: ids[10] }, data: { deletedAt: new Date() } });
    expect((await request('GET', '/categories/recent')).body.items.map((c: { id: string }) => c.id)).toEqual(ids.slice(0, 10).reverse());
    // Repeated use stays distinct, and backdating occurredOn does not hide a
    // newly recorded transaction. Equal createdAt values have stable ID order.
    const repeated = await expense(ids[0]);
    const repeatedRow = (await request('POST', '/transactions', { ...repeated, occurredOn: '2020-01-01' })).body.legs[0];
    const tied = await expense(ids[1]);
    const tiedRow = (await request('POST', '/transactions', tied)).body.legs[0];
    await prisma.transaction.updateMany({ where: { id: { in: [repeatedRow.id, tiedRow.id] } }, data: { createdAt: new Date('2026-09-25T00:00:00Z') } });
    const recent = (await request('GET', '/categories/recent')).body.items.map((c: { id: string }) => c.id);
    expect(recent).toHaveLength(10); expect(new Set(recent).size).toBe(10);
    expect(recent.slice(0, 2)).toEqual(ids.slice(0, 2).sort());
    expect((await request('GET', '/categories/recent', undefined, otherToken)).body.items).toEqual([]);
  });
  it('rolls back already moved transactions when category deletion fails', async () => {
    const source = await category(), target = await category('Target');
    const tx = (await request('POST', '/transactions', await expense(source.id))).body.legs[0];
    await prisma.$executeRawUnsafe(`CREATE FUNCTION category_delete_fault() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF OLD.id = '${source.id}'::uuid THEN RAISE EXCEPTION 'test fault'; END IF; RETURN OLD; END $$`);
    await prisma.$executeRawUnsafe('CREATE TRIGGER category_delete_fault BEFORE DELETE ON "Category" FOR EACH ROW EXECUTE FUNCTION category_delete_fault()');
    try {
      const result = await request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`);
      expect(result.status).toBe(503); expect(JSON.stringify(result.body)).not.toContain('test fault');
      const row = await prisma.transaction.findUniqueOrThrow({ where: { id: tx.id } });
      expect(row.categoryId).toBe(source.id); expect(row.version).toBe(1);
      expect((await request('GET', `/categories/${source.id}`)).status).toBe(200);
    } finally {
      await prisma.$executeRawUnsafe('DROP TRIGGER category_delete_fault ON "Category"');
      await prisma.$executeRawUnsafe('DROP FUNCTION category_delete_fault()');
    }
  });
  it('serializes category deletion with transaction creation and competing deletion', async () => {
    const source = await category(), target = await category('Target'), alternate = await category('Alternate');
    const input = await expense(source.id);
    const results = await Promise.all([
      request('POST', '/transactions', input),
      request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`),
      request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${alternate.id}`),
    ]);
    expect([201, 400]).toContain(results[0].status);
    expect(results.slice(1).map(r => r.status).sort()).toEqual([204, 404]);
    const rows = await prisma.transaction.findMany({ where: { userId: owner } });
    if (results[0].status === 201) {
      expect(rows).toHaveLength(1);
      expect(rows[0].categoryId).toBe(results[1].status === 204 ? target.id : alternate.id);
      expect(rows[0].version).toBe(2);
    } else expect(rows).toHaveLength(0);
  });
  it.each(['create', 'edit', 'restore'])('serializes archive with transaction %s', async action => {
    const source = await category(); const input = await expense(source.id);
    let id = '';
    if (action !== 'create') {
      id = (await request('POST', '/transactions', input)).body.legs[0].id;
      if (action === 'restore') await request('DELETE', `/transactions/${id}?version=1`);
    }
    const [write, archive] = await Promise.all([
      action === 'create' ? request('POST', '/transactions', input) : request('PATCH', `/transactions/${id}`, action === 'edit' ? { version: 1, notes: 'Edited' } : { version: 2, deleted: false }),
      request('PATCH', `/categories/${source.id}`, { version: 1, archived: true }),
    ]);
    expect(archive.status).toBe(200);
    expect(action === 'create' ? [201, 400] : [200, 400]).toContain(write.status);
    // Once archive commits, every subsequent write must reject the reference.
    expect((await request('POST', '/transactions', { ...input, legs: [{ ...input.legs[0], clientId: randomUUID() }] })).status).toBe(400);
    if (write.status === 400 && action === 'restore') expect((await prisma.transaction.findUniqueOrThrow({ where: { id } })).deletedAt).not.toBeNull();
  });
  it.each(['edit', 'restore'])('serializes delete/replace with transaction %s', async action => {
    const source = await category(), target = await category('Target');
    const id = (await request('POST', '/transactions', await expense(source.id))).body.legs[0].id;
    if (action === 'restore') await request('DELETE', `/transactions/${id}?version=1`);
    const [write, deletion] = await Promise.all([
      request('PATCH', `/transactions/${id}`, action === 'edit' ? { version: 1, notes: 'Edited' } : { version: 2, deleted: false }),
      request('DELETE', `/categories/${source.id}?version=1&replacementCategoryId=${target.id}`),
    ]);
    expect(deletion.status).toBe(204); expect([200, 409]).toContain(write.status);
    const row = await prisma.transaction.findUniqueOrThrow({ where: { id } });
    expect(row.categoryId).toBe(target.id);
    expect(row.version).toBe((action === 'restore' ? 2 : 1) + 1 + (write.status === 200 ? 1 : 0));
  });
  it('retries a category writer with an old snapshot and moves a newly committed transaction', async () => {
    const source = await category(), target = await category('Target');
    const input = await expense(source.id);
    let resume!: () => void, ready!: () => void;
    const paused = new Promise<void>(resolve => { ready = resolve; });
    const release = new Promise<void>(resolve => { resume = resolve; });
    let attempts = 0;
    // Only this repository gets the wrapper. The concurrent HTTP transaction
    // uses the real Prisma instance and can commit while this snapshot waits.
    const wrapped = {
      $transaction: (operation: (tx: Prisma.TransactionClient) => Promise<unknown>, options: object) =>
        prisma.$transaction(async tx => {
          attempts++;
          if (attempts === 1) {
            await tx.user.findUniqueOrThrow({ where: { id: owner } });
            ready(); await release;
          }
          return operation(tx);
        }, options),
    } as unknown as PrismaService;
    const repository = new PrismaCategoryRepository(wrapped);
    const deletion = repository.delete(owner, source.id, 1, target.id);
    await paused;
    try {
      expect((await request('POST', '/transactions', input)).status).toBe(201);
    } finally { resume(); }
    await deletion;
    expect(attempts).toBeGreaterThan(1);
    const row = await prisma.transaction.findFirstOrThrow({ where: { userId: owner } });
    expect(row.categoryId).toBe(target.id); expect(row.version).toBe(2);
  });

});
