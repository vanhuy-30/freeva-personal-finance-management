import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AccountModule } from '../src/modules/account/account.module';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-010 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let ownerEmail: string;
  let other: string;
  let token: string;
  let otherToken: string;
  let logs = '';
  const fixtureUsers: string[] = [];
  const stream = new Writable({ write(chunk, _encoding, callback) { logs += chunk.toString(); callback(); } });
  const amount = 9007199254740993n;
  const note = 'ghi chu rieng tu export';
  const wallet = 'Vi rieng tu export';

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{ serializers: { req: httpRequestSerializer }, redact: pinoRedactOptions }, stream] }),
        PrismaModule, AccountModule,
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
    const email = `${id}@example.test`;
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) },
    });
    return { id, bearer, email };
  }

  beforeEach(async () => {
    const first = await user();
    const second = await user();
    owner = first.id;
    ownerEmail = first.email;
    token = first.bearer;
    other = second.id;
    otherToken = second.bearer;
    logs = '';
  });

  afterAll(async () => {
    if (prisma) await cleanup(fixtureUsers);
    await app?.close();
  });

  async function cleanup(userIds: string[]) {
    await prisma.transactionTag.deleteMany({ where: { transaction: { userId: { in: userIds } } } });
    await prisma.transaction.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.category.updateMany({ where: { userId: { in: userIds } }, data: { parentId: null, groupId: null } });
    await prisma.category.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.categoryGroup.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.tag.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.financialAccount.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.fxQuote.deleteMany({ where: { userId: { in: userIds } } });
    await prisma.auditEvent.deleteMany({ where: { OR: [{ actorId: { in: userIds } }, { targetId: { in: userIds } }] } });
    await prisma.user.deleteMany({ where: { id: { in: userIds } } });
    await prisma.schemaMeta.upsert({ where: { id: 1 }, create: { id: 1, version: 1 }, update: { version: 1 } });
  }

  async function request(method: string, path: string, bearer = token) {
    const res = await fetch(`${base}/api/v1/account${path}`, {
      method,
      headers: bearer ? { Authorization: `Bearer ${bearer}` } : {},
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) as Record<string, unknown> : undefined };
  }

  async function ledger() {
    const account = await prisma.financialAccount.create({
      data: { userId: owner, clientId: randomUUID(), name: wallet, type: 'cash', currencyCode: 'VND', initialBalanceMinor: amount },
    });
    const group = await prisma.categoryGroup.create({ data: { userId: owner, clientId: randomUUID(), name: 'Nhom', isSystem: true } });
    const parent = await prisma.category.create({
      data: { userId: owner, clientId: randomUUID(), name: 'Cha', groupId: group.id, isSystem: true },
    });
    const category = await prisma.category.create({
      data: { userId: owner, clientId: randomUUID(), name: 'Con', groupId: group.id, parentId: parent.id },
    });
    const tag = await prisma.tag.create({ data: { userId: owner, clientId: randomUUID(), name: 'Nhan' } });
    const quote = await prisma.fxQuote.create({
      data: {
        userId: owner, clientId: randomUUID(), fromCode: 'VND', toCode: 'VND', rate: '1.50000000',
        quotedAt: new Date('2026-10-12T01:00:00.000Z'), source: 'manual',
      },
    });
    const active = await prisma.transaction.create({
      data: {
        userId: owner, clientId: randomUUID(), type: 'expense', amountMinor: -150000n, currencyCode: 'VND',
        occurredOn: new Date('2026-10-12'), accountId: account.id, categoryId: category.id, notes: note,
        tags: { create: { tagId: tag.id } },
      },
    });
    const removed = await prisma.transaction.create({
      data: {
        userId: owner, clientId: randomUUID(), type: 'income', amountMinor: amount, currencyCode: 'VND',
        occurredOn: new Date('2026-10-11'), accountId: account.id, deletedAt: new Date('2026-10-12T02:00:00.000Z'),
        fxQuoteId: quote.id,
      },
    });
    await prisma.oAuthIdentity.create({ data: { userId: owner, provider: 'google', subject: `secret-subject-${owner}` } });
    await prisma.financialAccount.create({
      data: { userId: other, clientId: randomUUID(), name: 'Vi nguoi khac', type: 'bank', currencyCode: 'VND', initialBalanceMinor: 1n },
    });
    return { account, active, removed, quote };
  }

  it('rejects a missing session', async () => {
    expect((await request('GET', '/export', '')).status).toBe(401);
    expect((await request('DELETE', '', '')).status).toBe(401);
  });

  it('exports only the owner snapshot and does not log secrets', async () => {
    const { account, removed } = await ledger();
    const result = await request('GET', '/export');
    expect(result.status).toBe(200);
    const body = result.body as {
      schemaVersion: number;
      userId: string;
      profile: { email: string };
      oauthProviders: string[];
      financialAccounts: Array<{ id: string; initialBalanceMinor: string; name: string }>;
      transactions: Array<{ id: string; amountMinor: string; deletedAt: string | null; notes: string | null; tagIds: string[] }>;
      fxQuotes: Array<{ rate: string }>;
      categories: Array<{ parentId: string | null }>;
    };
    expect(body.schemaVersion).toBe(1);
    expect(body.userId).toBe(owner);
    expect(body.profile.email).toBe(ownerEmail);
    expect(body.oauthProviders).toEqual(['google']);
    expect(body.financialAccounts.map(row => row.id)).toEqual([account.id]);
    expect(body.financialAccounts[0].initialBalanceMinor).toBe(amount.toString());
    expect(body.transactions.map(row => row.id).sort()).toEqual([removed.id, body.transactions.find(row => row.notes === note)!.id].sort());
    expect(body.transactions.find(row => row.id === removed.id)?.deletedAt).not.toBeNull();
    expect(body.transactions.find(row => row.notes === note)?.tagIds).toHaveLength(1);
    expect(body.fxQuotes[0].rate).toBe('1.50000000');
    expect(body.categories.some(row => row.parentId)).toBe(true);
    const text = JSON.stringify(body);
    expect(text).not.toContain('passwordHash');
    expect(text).not.toContain('secret-subject');
    expect(text).not.toContain('Vi nguoi khac');
    const otherExport = await request('GET', '/export', otherToken);
    expect(JSON.stringify(otherExport.body)).not.toContain(wallet);
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'user.data_export', targetId: owner, outcome: 'success' } })).toBe(1);
    for (const secret of [token, note, wallet, amount.toString(), ownerEmail, 'secret-subject']) {
      expect(logs).not.toContain(secret);
    }
  });

  it('deletes the owner immediately and keeps the audit uuid', async () => {
    await ledger();
    const hash = createHash('sha256').update(token).digest('hex');
    await prisma.authToken.create({
      data: { userId: owner, purpose: 'reset_password', tokenHash: randomBytes(32).toString('hex'), expiresAt: new Date(Date.now() + 60_000) },
    });
    await prisma.authMailJob.create({
      data: { userId: owner, purpose: 'verify_email', encryptedToken: 'cipher', expiresAt: new Date(Date.now() + 60_000) },
    });
    const result = await request('DELETE', '');
    expect(result.status).toBe(204);
    expect(result.body).toBeUndefined();
    expect(await prisma.user.findUnique({ where: { id: owner } })).toBeNull();
    expect(await prisma.financialAccount.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.category.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.authSession.count({ where: { tokenHash: hash } })).toBe(0);
    expect(await prisma.authToken.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.authMailJob.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.oAuthIdentity.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.user.findUnique({ where: { id: other } })).not.toBeNull();
    expect(await prisma.financialAccount.count({ where: { userId: other } })).toBe(1);
    const audit = await prisma.auditEvent.findFirst({ where: { action: 'user.account_delete', targetId: owner } });
    expect(audit).toMatchObject({ actorType: 'user', actorId: owner, outcome: 'success' });
    expect((await request('GET', '/export')).status).toBe(401);
    expect((await request('DELETE', '')).status).toBe(401);
    for (const secret of [token, note, ownerEmail]) expect(logs).not.toContain(secret);
  });

  it('still deletes when schema meta is missing and does not export', async () => {
    await prisma.schemaMeta.delete({ where: { id: 1 } });
    try {
      const exported = await request('GET', '/export');
      expect(exported.status).toBe(503);
      expect(exported.body).toMatchObject({ error: { code: 'ACCOUNT_UNAVAILABLE' } });
      expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'user.data_export' } })).toBe(0);
      expect((await request('DELETE', '')).status).toBe(204);
      expect(await prisma.user.findUnique({ where: { id: owner } })).toBeNull();
      expect(await prisma.auditEvent.count({ where: { targetId: owner, action: 'user.account_delete' } })).toBe(1);
    } finally {
      await prisma.schemaMeta.upsert({ where: { id: 1 }, create: { id: 1, version: 1 }, update: { version: 1 } });
    }
  });
});
