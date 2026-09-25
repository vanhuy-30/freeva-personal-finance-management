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
import { PrismaFinancialAccountRepository } from '../src/modules/financial-accounts/infrastructure/prisma-financial-account.repository';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-005 HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule,
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
  async function request(method = 'GET', path = '', body?: object, bearer = token, idempotencyKey?: string) {
    const res = await fetch(`${base}/api/v1/transactions${path}`, {
      method, headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(method === 'POST' ? { 'Idempotency-Key': idempotencyKey ?? (body as { legs?: { clientId?: string }[] })?.legs?.[0]?.clientId ?? '' } : {}), ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }
  async function account(currencyCode = 'VND', userId = owner) {
    return prisma.financialAccount.create({ data: { userId, clientId: randomUUID(), name: 'Private test wallet', type: 'cash', currencyCode, initialBalanceMinor: 0n } });
  }
  async function input(type = 'transfer', fx = false) {
    const source = await account(fx ? 'USD' : 'VND'); const destination = await account();
    const categoryId = type === 'expense' ? (await prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Expense fixture' } })).id : null;
    return { type, categoryId, occurredOn: '2026-09-25', notes: 'Private transaction note', legs: [
      { clientId: randomUUID(), accountId: source.id, currencyCode: source.currencyCode, amountMinor: type === 'income' ? '9007199254740993' : fx ? '-1000' : '-9007199254740993' },
      ...(type === 'transfer' ? [{ clientId: randomUUID(), accountId: destination.id, currencyCode: 'VND', amountMinor: fx ? '250000' : '9007199254740993' }] : []),
    ], ...(fx ? { fx: { rate: '25000', quotedAt: '2026-09-25T10:00:00+07:00' } } : {}) };
  }
  async function balance(id: string) {
    const res = await fetch(`${base}/api/v1/financial-accounts/${id}`, { headers: { Authorization: `Bearer ${token}` } });
    expect(res.status).toBe(200); return (await res.json() as { balanceMinor: string }).balanceMinor;
  }
  async function create(body: object) {
    const res = await request('POST', '', body); expect(res.status).toBe(201); return res.body;
  }
  it.each(['income', 'expense', 'transfer'])('creates, reads, edits, deletes and restores %s with exact derived balances', async type => {
    const data = await input(type); const created = await create(data); const first = created.legs[0];
    expect(created.legs).toHaveLength(type === 'transfer' ? 2 : 1);
    expect(await balance(first.accountId)).toBe(first.amountMinor);
    expect((await request('GET', `/${first.id}`)).body).toEqual(created);
    expect((await request()).body.total).toBe(created.legs.length);
    const changed = await request('PATCH', `/${created.legs.at(-1).id}`, { version: 1, occurredOn: '2024-02-29', notes: null });
    expect(changed.status).toBe(200);
    for (const leg of changed.body.legs) expect(leg).toMatchObject({ version: 2, occurredOn: '2024-02-29', notes: null });
    expect((await request('DELETE', `/${first.id}?version=2`)).status).toBe(204);
    expect(await balance(first.accountId)).toBe('0'); expect((await request()).body.total).toBe(0);
    const removed = (await request('GET', `/${first.id}`)).body;
    expect(new Set(removed.legs.map((leg: { deletedAt: string }) => leg.deletedAt)).size).toBe(1);
    expect((await request('GET', '?status=deleted')).body.total).toBe(created.legs.length);
    expect((await request('PATCH', `/${first.id}`, { version: 3, deleted: false })).status).toBe(200);
    expect(await balance(first.accountId)).toBe(first.amountMinor);
    expect(JSON.stringify(created)).not.toContain(owner);
  });
  it('normalizes replay, handles concurrent create, detects clientId collisions and does not restore deleted replay', async () => {
    const data = await input();
    const responses = await Promise.all([request('POST', '', data), request('POST', '', data)]);
    expect(responses.map(res => res.status).sort()).toEqual([200, 201]);
    const first = responses[0].body.legs[0];
    const retry = { ...data, legs: data.legs.map(item => ({ ...item, clientId: item.clientId.toUpperCase(), amountMinor: item.amountMinor.replace('900', '0900') })) };
    expect((await request('POST', '', retry)).status).toBe(200);
    expect((await request('POST', '', { ...data, notes: 'Different' })).status).toBe(409);
    expect((await request('POST', '', { ...data, legs: [data.legs[0], { ...data.legs[1], clientId: randomUUID() }] })).status).toBe(409);
    expect((await request('DELETE', `/${first.id}?version=1`)).status).toBe(204);
    expect((await request('POST', '', data)).body.legs[0].deletedAt).not.toBeNull();
    expect(await balance(first.accountId)).toBe('0');
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(2);
  });
  it('requires Idempotency-Key to match the source clientId', async () => {
    const data = await input();
    expect((await request('POST', '', data, token, '')).status).toBe(400);
    expect((await request('POST', '', data, token, randomUUID())).status).toBe(400);
    expect((await request('POST', '', data, token, data.legs[1].clientId)).status).toBe(400);
    expect((await request('POST', '', data, token, data.legs[0].clientId.toUpperCase())).status).toBe(201);
  });
  it('requires a valid active owner category for expenses, including patches', async () => {
    const data = await input('expense');
    expect((await request('POST', '', { ...data, categoryId: null })).status).toBe(400);
    const created = await create(data);
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 1, categoryId: null })).status).toBe(400);
    await prisma.category.update({ where: { id: data.categoryId! }, data: { archivedAt: new Date() } });
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 1, notes: 'Edit' })).status).toBe(400);
    expect((await request('DELETE', `/${created.legs[0].id}?version=1`)).status).toBe(204);
  });
  it('enforces ownership and active sessions for reads and every mutation', async () => {
    const data = await input(); const created = await create(data); const id = created.legs[0].id;
    for (const target of [id, randomUUID()]) for (const [method, path, body] of [
      ['GET', `/${target}`, undefined], ['PATCH', `/${target}`, { version: 1 }], ['DELETE', `/${target}?version=1`, undefined],
    ] as const) expect((await request(method, path, body, otherToken)).status).toBe(404);
    expect((await request('GET', '', undefined, otherToken)).body.total).toBe(0);
    const foreign = await account('VND', other);
    expect((await request('POST', '', { ...data, legs: data.legs.map(item => ({ ...item, clientId: randomUUID(), accountId: foreign.id })) })).status).toBe(404);
    for (const [method, path, body] of [['GET', '', undefined], ['GET', `/${id}`, undefined], ['POST', '', data], ['PATCH', `/${id}`, { version: 1 }], ['DELETE', `/${id}?version=1`, undefined]] as const) expect((await request(method, path, body, '')).status).toBe(401);
    await prisma.authSession.deleteMany({ where: { userId: owner } });
    expect((await request()).status).toBe(401);
  });
  it('validates date, nested fields, signs, same-account, currencies, versions and query bounds', async () => {
    const data = await input();
    for (const extra of [
      { occurredOn: '2026-02-29' }, { occurredOn: '2026-04-31' }, { occurredOn: '2026-01-01T00:00:00Z' }, { userId: other },
      { legs: null }, { legs: [null] }, { legs: [] }, { legs: [data.legs[0]] }, { legs: [...data.legs, data.legs[0]] },
      { legs: data.legs.map(item => ({ ...item, amountMinor: '0' })) }, { legs: data.legs.map(item => ({ ...item, accountId: data.legs[0].accountId })) },
      { legs: data.legs.map(item => ({ ...item, amountMinor: 100 })) }, { legs: [...data.legs].reverse() },
      { legs: data.legs.map(item => ({ ...item, currencyCode: 'USD' })) },
      { legs: [{ ...data.legs[0], amountMinor: '-9223372036854775809' }, data.legs[1]] },
      { legs: [{ ...data.legs[0], amountMinor: '-1\n' }, data.legs[1]] }, { legs: [{ ...data.legs[0], transferGroupId: randomUUID() }, data.legs[1]] },
      { fx: { rate: '1', quotedAt: '2026-09-25T00:00:00Z' } }, { fx: [] }, { tagIds: null }, { notes: 'x'.repeat(2001) },
    ]) expect((await request('POST', '', { ...data, ...extra })).status).toBe(400);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    const created = await create(data); const id = created.legs[0].id;
    for (const patch of [{}, { version: null }, { version: 0 }, { version: 2147483647 }, { version: 1, type: 'income' }, { version: 1, deleted: null }]) expect((await request('PATCH', `/${id}`, patch)).status).toBe(400);
    for (const path of ['?page=0', '?pageSize=101', '?from=2026-02-29', '?from=2026-10-01&to=2026-09-01', '?status=bad', '?owner=x', '/bad-id']) expect((await request('GET', path)).status).toBe(400);
    expect((await request('DELETE', `/${id}`)).status).toBe(400);
  });
  it('stores immutable manual FX with exact minor-digit conversion and edits both legs together', async () => {
    const data = await input('transfer', true); const created = await create(data);
    expect(created.fx).toMatchObject({ rate: '25000.00000000', quotedAt: '2026-09-25T03:00:00.000Z', fromCode: 'USD', toCode: 'VND' });
    expect(new Set(created.legs.map((leg: { fxQuoteId: string }) => leg.fxQuoteId))).toEqual(new Set([created.fx.id]));
    expect((await request('POST', '', data)).status).toBe(200);
    const changed = await request('PATCH', `/${created.legs[1].id}`, { version: 1, legs: [data.legs[0], { ...data.legs[1], amountMinor: '260000' }], fx: { rate: '26000', quotedAt: '2026-09-25T04:00:00Z' } });
    expect(changed.status).toBe(200); expect(changed.body.fx.id).not.toBe(created.fx.id);
    expect((await prisma.fxQuote.findUniqueOrThrow({ where: { id: created.fx.id } })).rate.toFixed(8)).toBe('25000.00000000');
    expect(await balance(data.legs[1].accountId)).toBe('260000');
    for (const extra of [{ fx: null }, { fx: { rate: '0', quotedAt: '2026-09-25T00:00:00Z' } }, { fx: { rate: '0.00000001', quotedAt: '2026-09-25T00:00:00Z' } }, { legs: [data.legs[0], { ...data.legs[1], amountMinor: '1' }] }]) {
      expect((await request('PATCH', `/${created.legs[0].id}`, { version: 2, ...extra })).status).toBe(400);
    }
    expect(await balance(data.legs[1].accountId)).toBe('260000');
  });
  it('checks category and tag ownership, nullable patch, and transfer category restriction', async () => {
    const category = await prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Food' } });
    const tag = await prisma.tag.create({ data: { userId: owner, clientId: randomUUID(), name: 'Personal' } });
    const foreign = await prisma.tag.create({ data: { userId: other, clientId: randomUUID(), name: 'Foreign' } });
    const data = await input('income'); const created = await create({ ...data, categoryId: category.id, tagIds: [tag.id] });
    expect(created.legs[0]).toMatchObject({ categoryId: category.id, tagIds: [tag.id] });
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 1, tagIds: [foreign.id] })).status).toBe(400);
    const changed = await request('PATCH', `/${created.legs[0].id}`, { version: 1, categoryId: null, tagIds: [], notes: null });
    expect(changed.body.legs[0]).toMatchObject({ categoryId: null, tagIds: [], notes: null });
    expect((await request('POST', '', { ...await input(), categoryId: category.id })).status).toBe(400);
    expect((await request('POST', '', { ...await input('income'), categoryId: randomUUID() })).status).toBe(400);
  });
  it('allows only one winner for concurrent updates through opposite transfer legs', async () => {
    const data = await input(); const created = await create(data);
    const results = await Promise.all(created.legs.map((leg: { id: string }, index: number) => request('PATCH', `/${leg.id}`, { version: 1, notes: `revision ${index}` })));
    expect(results.map(result => result.status).sort()).toEqual([200, 409]);
    const current = (await request('GET', `/${created.legs[0].id}`)).body;
    expect(current.legs.map((leg: { version: number }) => leg.version)).toEqual([2, 2]);
    expect(new Set(current.legs.map((leg: { notes: string }) => leg.notes)).size).toBe(1);
  });
  it('rolls back first leg and FX quote when the second leg write fails', async () => {
    const data = await input('transfer', true);
    // Unique trigger scoped to this test's random clientId; installed only in guarded disposable DB.
    await prisma.$executeRawUnsafe(`CREATE FUNCTION test_fail_transfer_leg() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW."clientId" = '${data.legs[1].clientId}'::uuid THEN RAISE EXCEPTION 'injected failure'; END IF; RETURN NEW; END $$`);
    await prisma.$executeRawUnsafe('CREATE TRIGGER test_fail_transfer_leg BEFORE INSERT ON "Transaction" FOR EACH ROW EXECUTE FUNCTION test_fail_transfer_leg()');
    try {
      expect((await request('POST', '', data)).status).toBe(503);
      expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
      expect(await prisma.fxQuote.count({ where: { userId: owner } })).toBe(0);
      expect(await balance(data.legs[0].accountId)).toBe('0');
    } finally {
      await prisma.$executeRawUnsafe('DROP TRIGGER test_fail_transfer_leg ON "Transaction"');
      await prisma.$executeRawUnsafe('DROP FUNCTION test_fail_transfer_leg()');
    }
    await create(data);
  });
  it('locks account denomination after history, rejects archived writes, allows deletion but requires active wallets to restore', async () => {
    const data = await input(); const created = await create(data); const id = created.legs[0].id;
    const repository = new PrismaFinancialAccountRepository(prisma);
    await expect(repository.update(owner, data.legs[0].accountId, { version: 1, currencyCode: 'USD' })).rejects.toThrow('ACCOUNT_CONFLICT');
    await repository.update(owner, data.legs[0].accountId, { version: 1, archived: true });
    expect((await request('PATCH', `/${id}`, { version: 1, notes: 'edit' })).status).toBe(409);
    expect((await request('DELETE', `/${id}?version=1`)).status).toBe(204);
    expect((await request('PATCH', `/${id}`, { version: 2, deleted: false })).status).toBe(409);
    await repository.update(owner, data.legs[0].accountId, { version: 2, archived: false });
    expect((await request('PATCH', `/${id}`, { version: 2, deleted: false })).status).toBe(200);
  });
  it('moves both legs atomically and preserves identity and optimistic version limits', async () => {
    const data = await input(); const created = await create(data); const next = await account();
    const replacement = [{ ...data.legs[0], accountId: next.id, amountMinor: '-150000' }, { ...data.legs[1], amountMinor: '150000' }];
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 1, legs: replacement })).status).toBe(200);
    expect(await balance(data.legs[0].accountId)).toBe('0');
    expect(await balance(next.id)).toBe('-150000');
    expect(await balance(data.legs[1].accountId)).toBe('150000');
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 2, legs: [{ ...replacement[0], clientId: randomUUID() }, replacement[1]] })).status).toBe(409);
    await prisma.transaction.updateMany({ where: { userId: owner }, data: { version: 2147483646 } });
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 2147483646, notes: 'Last version' })).body.legs[0].version).toBe(2147483647);
    expect((await request('PATCH', `/${created.legs[0].id}`, { version: 2147483646 })).status).toBe(409);
  });
  it('rolls back pair edits and soft-delete when the second update fails', async () => {
    const data = await input(); const created = await create(data);
    await prisma.$executeRawUnsafe(`CREATE FUNCTION test_fail_transfer_update() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.id = '${created.legs[1].id}'::uuid THEN RAISE EXCEPTION 'injected failure'; END IF; RETURN NEW; END $$`);
    await prisma.$executeRawUnsafe('CREATE TRIGGER test_fail_transfer_update BEFORE UPDATE ON "Transaction" FOR EACH ROW EXECUTE FUNCTION test_fail_transfer_update()');
    try {
      expect((await request('PATCH', `/${created.legs[0].id}`, { version: 1, notes: 'Must roll back' })).status).toBe(503);
      expect((await request('DELETE', `/${created.legs[0].id}?version=1`)).status).toBe(503);
      expect((await request('GET', `/${created.legs[0].id}`)).body).toEqual(created);
      expect(await balance(data.legs[0].accountId)).toBe(data.legs[0].amountMinor);
    } finally {
      await prisma.$executeRawUnsafe('DROP TRIGGER test_fail_transfer_update ON "Transaction"');
      await prisma.$executeRawUnsafe('DROP FUNCTION test_fail_transfer_update()');
    }
  });
  it('invalidates an account writer snapshot that predates the first transaction', async () => {
    const data = await input('expense');
    const original = prisma.$transaction.bind(prisma);
    let release!: () => void; let entered!: () => void;
    const blocked = new Promise<void>(resolve => { release = resolve; });
    const ready = new Promise<void>(resolve => { entered = resolve; });
    let intercept = true;
    const spy = jest.spyOn(prisma, '$transaction').mockImplementation(((operation: (tx: Prisma.TransactionClient) => Promise<unknown>, options: object) =>
      original(async tx => {
        if (!intercept) return operation(tx);
        intercept = false;
        // Establish account mutation's Repeatable Read snapshot before the writer commits.
        await tx.financialAccount.findUniqueOrThrow({ where: { id: data.legs[0].accountId } });
        entered(); await blocked;
        return operation(tx);
      }, options)) as typeof prisma.$transaction);
    const repository = new PrismaFinancialAccountRepository(prisma);
    const pending = repository.update(owner, data.legs[0].accountId, { version: 1, currencyCode: 'USD' });
    // Attach rejection handling immediately; asserting happens after releasing the barrier.
    const outcome = pending.then(() => 'unexpected success', (error: Error) => error.message);
    try {
      await ready;
      await create(data);
      release();
      expect(await outcome).toBe('ACCOUNT_CONFLICT');
      expect((await prisma.financialAccount.findUniqueOrThrow({ where: { id: data.legs[0].accountId } })).currencyCode).toBe('VND');
    } finally { release(); await outcome; spy.mockRestore(); }
  });
  it('serializes a new transaction against concurrent account archive', async () => {
    const data = await input('expense');
    const repository = new PrismaFinancialAccountRepository(prisma);
    const [created] = await Promise.all([request('POST', '', data), repository.update(owner, data.legs[0].accountId, { version: 1, archived: true })]);
    expect([201, 409]).toContain(created.status);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(created.status === 201 ? 1 : 0);
    const fresh = { ...data, legs: [{ ...data.legs[0], clientId: randomUUID() }] };
    expect((await request('POST', '', fresh)).status).toBe(409);
  });
  it('filters per leg, paginates deterministically and does not log private values', async () => {
    const income = await input('income'); await create(income);
    const transfer = await input(); const created = await create(transfer);
    expect((await request('GET', '?type=income')).body.total).toBe(1);
    expect((await request('GET', `?accountId=${transfer.legs[1].accountId}`)).body.items.map((leg: { id: string }) => leg.id)).toEqual([created.legs[1].id]);
    expect((await request('GET', '?from=2026-09-25&to=2026-09-25&search=private')).body.total).toBe(3);
    expect((await request('GET', '?to=2026-09-24')).body.total).toBe(0);
    const pages = await Promise.all([1, 2, 3].map(page => request('GET', `?page=${page}&pageSize=1`)));
    expect(new Set(pages.map(page => page.body.items[0].id)).size).toBe(3);
    for (const secret of [token, '9007199254740993', 'Private transaction note']) expect(logs).not.toContain(secret);
  });
});
