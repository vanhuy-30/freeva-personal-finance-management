import type { Prisma } from '@prisma/client';
import type { FinancialAccount } from '../src/modules/financial-accounts/domain/financial-account';
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
import { FINANCIAL_ACCOUNT_REPOSITORY } from '../src/modules/financial-accounts/domain/financial-account.repository';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-004 HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule,
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
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  async function request(method = 'GET', path = '', body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1/financial-accounts${path}`, {
      method, headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }
  function input(extra = {}) {
    return { clientId: randomUUID(), name: 'Ví thử nghiệm riêng tư', type: 'cash', currencyCode: 'VND', initialBalanceMinor: '9007199254740993', ...extra };
  }
  async function create(extra = {}) {
    const result = await request('POST', '', input(extra));
    expect(result.status).toBe(201);
    expect(result.body).not.toHaveProperty('userId');
    return result.body;
  }
  async function transaction(accountId: string, amountMinor: bigint, extra = {}) {
    return prisma.transaction.create({ data: {
      userId: owner, clientId: randomUUID(), accountId, amountMinor, type: amountMinor < 0n ? 'expense' : 'income',
      currencyCode: 'VND', occurredOn: new Date('2026-09-24'), ...extra,
    } });
  }

  it.each(['cash', 'bank', 'ewallet', 'credit'])('creates and reads %s with exact initial balance', async type => {
    const account = await create({ type, ...(type === 'credit' ? { creditLimitMinor: '9223372036854775807', statementCloseDay: 28, paymentDueDay: 1 } : {}) });
    expect(account.balanceMinor).toBe('9007199254740993');
    expect(account.version).toBe(1);
    expect((await request('GET', `/${account.id}`)).body).toEqual(account);
    expect((await request()).body.items).toEqual([account]);
  });

  it('rejects invalid input without reflecting financial values', async () => {
    for (const extra of [
      { initialBalanceMinor: 100 }, { initialBalanceMinor: '9223372036854775808' }, { initialBalanceMinor: '-9223372036854775809' },
      { initialBalanceMinor: '1.2' }, { initialBalanceMinor: '1\n' }, { initialBalanceMinor: '1e5' },
      { name: ' ' }, { name: null }, { name: 'x'.repeat(101) }, { currencyCode: 'ZZZ' }, { currencyCode: 'VND\n' },
      { sortOrder: -1 }, { sortOrder: null }, { sortOrder: 2147483648 }, { type: 'investment' },
      { creditLimitMinor: '1' }, { type: 'credit', creditLimitMinor: '-1' }, { type: 'credit', statementCloseDay: 29 },
      { type: 'credit', paymentDueDay: 0 }, { userId: other }, { archivedAt: new Date().toISOString() },
    ]) {
      const result = await request('POST', '', input(extra));
      expect(result).toMatchObject({ status: 400, body: { error: { code: 'VALIDATION_ERROR' } } });
      expect(JSON.stringify(result.body)).not.toContain('Ví thử nghiệm riêng tư');
    }
    for (const path of ['?page=0', '?pageSize=101', '?status=bad', '?userId=bad', '/not-a-uuid']) {
      expect((await request('GET', path)).status).toBe(400);
    }
    const account = await create();
    for (const patch of [{}, { version: null }, { version: 1, initialBalanceMinor: null }, { version: 1, archived: null }]) {
      expect((await request('PATCH', `/${account.id}`, patch)).status).toBe(400);
    }
    expect((await request('DELETE', `/${account.id}`)).status).toBe(400);
  });

  it('enforces owner and live session on every operation', async () => {
    const account = await create();
    for (const id of [account.id, randomUUID()]) {
      for (const [method, path, body] of [
        ['GET', `/${id}`, undefined], ['PATCH', `/${id}`, { version: 1, name: 'Changed' }], ['DELETE', `/${id}?version=1`, undefined],
      ] as const) expect((await request(method, path, body, otherToken)).status).toBe(404);
    }
    expect((await request('GET', '', undefined, otherToken)).body.total).toBe(0);
    for (const bearer of ['', randomBytes(32).toString('hex')]) {
      expect((await request('GET', '', undefined, bearer)).status).toBe(401);
      expect((await request('POST', '', input(), bearer)).status).toBe(401);
      expect((await request('GET', `/${account.id}`, undefined, bearer)).status).toBe(401);
      expect((await request('PATCH', `/${account.id}`, { version: 1 }, bearer)).status).toBe(401);
      expect((await request('DELETE', `/${account.id}?version=1`, undefined, bearer)).status).toBe(401);
    }
    await prisma.authSession.updateMany({ where: { userId: owner }, data: { expiresAt: new Date(0) } });
    expect((await request()).status).toBe(401);
    await prisma.authSession.deleteMany({ where: { userId: other } });
    expect((await request('GET', '', undefined, otherToken)).status).toBe(401);
  });

  it('handles normalized retries, duplicate conflicts and simultaneous creates', async () => {
    const body = input({ name: '  Wallet  ', initialBalanceMinor: '-0' });
    const results = await Promise.all([request('POST', '', body), request('POST', '', body)]);
    expect(results.map(r => r.status).sort()).toEqual([200, 201]);
    const account = results[0].body;
    expect(results[1].body.id).toBe(account.id);
    expect((await request('POST', '', { ...body, clientId: body.clientId.toUpperCase(), name: 'Wallet', initialBalanceMinor: '00', sortOrder: 0, creditLimitMinor: null })).status).toBe(200);
    expect((await request('POST', '', { ...body, initialBalanceMinor: '1' })).status).toBe(409);
    expect((await request('POST', '', body, otherToken)).status).toBe(201);
    await request('DELETE', `/${account.id}?version=1`);
    const replay = await request('POST', '', body);
    expect(replay.status).toBe(200);
    expect(replay.body.archivedAt).not.toBeNull();
    const conflicting = input();
    const race = await Promise.all([request('POST', '', conflicting), request('POST', '', { ...conflicting, name: 'Different' })]);
    expect(race.map(r => r.status).sort()).toEqual([201, 409]);
  });

  it('atomically applies one of two writes with the same version', async () => {
    const account = await create();
    const results = await Promise.all([
      request('PATCH', `/${account.id}`, { version: 1, initialBalanceMinor: '11' }),
      request('PATCH', `/${account.id}`, { version: 1, initialBalanceMinor: '22' }),
    ]);
    expect(results.map(r => r.status).sort()).toEqual([200, 409]);
    const saved = (await request('GET', `/${account.id}`)).body;
    expect(saved.version).toBe(2);
    expect(['11', '22']).toContain(saved.balanceMinor);
    expect((await request('DELETE', `/${account.id}?version=1`)).status).toBe(409);
  });

  it('derives balances from signed active transactions without changing history', async () => {
    const account = await create({ initialBalanceMinor: '-100' });
    const destination = await create({ initialBalanceMinor: '0' });
    const group = randomUUID();
    await transaction(account.id, 1000n);
    await transaction(account.id, -200n);
    await transaction(account.id, -300n, { type: 'transfer', transferGroupId: group });
    await transaction(destination.id, 300n, { type: 'transfer', transferGroupId: group });
    await transaction(account.id, 999n, { deletedAt: new Date() });
    // Defensive owner scoping, even if legacy data contains an inconsistent relation.
    await transaction(account.id, 888n, { userId: other });
    expect((await request('GET', `/${account.id}`)).body.balanceMinor).toBe('400');
    expect((await request('GET', `/${destination.id}`)).body.balanceMinor).toBe('300');
    const before = await prisma.transaction.findMany({ where: { accountId: account.id }, orderBy: { id: 'asc' } });
    const changed = await request('PATCH', `/${account.id}`, { version: 1, initialBalanceMinor: '0' });
    expect(changed.body.balanceMinor).toBe('500');
    expect(await prisma.transaction.findMany({ where: { accountId: account.id }, orderBy: { id: 'asc' } })).toEqual(before);
    expect((await request('PATCH', `/${account.id}`, { version: 2, type: 'bank' })).status).toBe(409);
    expect((await request('PATCH', `/${account.id}`, { version: 2, currencyCode: 'USD' })).status).toBe(409);
    const onlyDeleted = await create();
    await transaction(onlyDeleted.id, 1n, { deletedAt: new Date() });
    expect((await request('PATCH', `/${onlyDeleted.id}`, { version: 1, currencyCode: 'USD' })).status).toBe(409);
    expect((await request()).body.items.find((item: { id: string }) => item.id === account.id).balanceMinor).toBe('500');
  });

  it('reads account fields and ledger from one snapshot across a concurrent commit', async () => {
    const account = await create({ initialBalanceMinor: '100' });
    const entry = await transaction(account.id, 10n);
    // Commit between the account read and ledger read, without relying on timing/sleeps.
    const repository = app.get<PrismaFinancialAccountRepository>(FINANCIAL_ACCOUNT_REPOSITORY);
    type BalanceReader = {
      balances(tx: Prisma.TransactionClient, userId: string, rows: Omit<FinancialAccount, 'balanceMinor'>[]): Promise<FinancialAccount[]>;
    };
    const reader = repository as unknown as BalanceReader;
    const original = reader.balances.bind(reader);
    const spy = jest.spyOn(reader, 'balances').mockImplementationOnce(async (tx, userId, rows) => {
      await prisma.$transaction([
        prisma.financialAccount.update({ where: { id: account.id }, data: { initialBalanceMinor: 1000n } }),
        prisma.transaction.update({ where: { id: entry.id }, data: { amountMinor: 100n } }),
      ]);
      return original(tx, userId, rows);
    });
    try {
      expect((await request('GET', `/${account.id}`)).body).toMatchObject({ initialBalanceMinor: '100', balanceMinor: '110' });
    } finally { spy.mockRestore(); }
    expect((await request('GET', `/${account.id}`)).body).toMatchObject({ initialBalanceMinor: '1000', balanceMinor: '1100' });
  });

  it('supports sums outside int64 and initial bigint boundaries', async () => {
    const max = '9223372036854775807';
    const account = await create({ initialBalanceMinor: max });
    await transaction(account.id, BigInt(max));
    await transaction(account.id, BigInt(max));
    expect((await request('GET', `/${account.id}`)).body.balanceMinor).toBe('27670116110564327421');
    expect((await create({ initialBalanceMinor: '-9223372036854775808' })).balanceMinor).toBe('-9223372036854775808');
  });

  it('changes unused type/currency, clears credit fields, archives and restores history', async () => {
    const account = await create({ type: 'credit', creditLimitMinor: '10000', statementCloseDay: 10, paymentDueDay: 20 });
    const changed = await request('PATCH', `/${account.id}`, { version: 1, type: 'bank', currencyCode: 'USD' });
    expect(changed.body).toMatchObject({ type: 'bank', currencyCode: 'USD', creditLimitMinor: null, statementCloseDay: null, paymentDueDay: null, version: 2 });
    await transaction(account.id, -10n, { currencyCode: 'USD' });
    expect((await request('DELETE', `/${account.id}?version=2`)).status).toBe(204);
    const archived = (await request('GET', `/${account.id}`)).body;
    expect(archived.archivedAt).not.toBeNull();
    expect((await request()).body.total).toBe(0);
    expect((await request('GET', '?status=archived')).body.items).toEqual([archived]);
    expect((await request('GET', '?status=all')).body.total).toBe(1);
    const restored = await request('PATCH', `/${account.id}`, { version: 3, archived: false });
    expect(restored.body).toMatchObject({ archivedAt: null, version: 4, balanceMinor: '9007199254740983' });
    expect(await prisma.transaction.count({ where: { accountId: account.id } })).toBe(1);
    const card = await create({ type: 'credit', creditLimitMinor: '100' });
    expect((await request('PATCH', `/${card.id}`, { version: 1, creditLimitMinor: null })).body.creditLimitMinor).toBeNull();
  });

  it('paginates in stable sortOrder/createdAt/id order', async () => {
    const first = await create({ sortOrder: 5 });
    const second = await create({ sortOrder: 1 });
    const third = await create({ sortOrder: 1 });
    const stamp = new Date('2026-01-01');
    await prisma.financialAccount.updateMany({ where: { userId: owner }, data: { createdAt: stamp } });
    const sorted = [second.id, third.id].sort().concat(first.id);
    const page = await request('GET', '?pageSize=2');
    expect(page.body).toMatchObject({ page: 1, pageSize: 2, total: 3 });
    expect(page.body.items.map((item: { id: string }) => item.id)).toEqual(sorted.slice(0, 2));
    expect((await request('GET', '?page=2&pageSize=2')).body.items[0].id).toBe(first.id);
    expect((await request('GET', '?page=3&pageSize=2')).body.items).toEqual([]);
    expect((await request('GET', '?page=2147483647&pageSize=100')).body.items).toEqual([]);
    expect((await request('PATCH', `/${first.id}`, { version: 1, sortOrder: 0 })).status).toBe(200);
    expect((await request()).body.items[0].id).toBe(first.id);
  });

  it('keeps financial data out of HTTP logs and sanitizes infrastructure failures', async () => {
    const account = await create({ name: 'secret-wallet-name', initialBalanceMinor: '87654321987654321' });
    await request('GET', `/${account.id}`);
    const repository = app.get<PrismaFinancialAccountRepository>(FINANCIAL_ACCOUNT_REPOSITORY);
    const spy = jest.spyOn(repository, 'find').mockRejectedValueOnce(new Error('secret-wallet-name 87654321987654321'));
    try {
      expect(await request('GET', `/${account.id}`)).toEqual({ status: 503, body: { error: {
        code: 'ACCOUNTS_UNAVAILABLE', message: 'Financial accounts are temporarily unavailable', details: [],
      } } });
    } finally { spy.mockRestore(); }
    expect(logs).toContain('financial-accounts');
    for (const secret of ['secret-wallet-name', '87654321987654321', token]) expect(logs).not.toContain(secret);
  });
});
