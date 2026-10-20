import { TagModule } from '../src/modules/tags/tag.module';
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

describe('BE-P1-012 tags HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, TagModule,
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
      await prisma.tag.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  async function request(method = 'GET', path = '/tags', body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1${path}`, { method,
      headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
        ...(path === '/transactions' && method === 'POST' ? { 'Idempotency-Key': (body as { legs: { clientId: string }[] }).legs[0].clientId } : {}) },
      body: body ? JSON.stringify(body) : undefined });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }
  async function createTag(name = 'Work', clientId = randomUUID(), bearer = token) {
    const result = await request('POST', '/tags', { clientId, name }, bearer);
    expect(result.status).toBe(201);
    return result.body as { id: string; clientId: string; name: string; version: number };
  }

  it('CRUD is owner-scoped with clientId replay and foreign 404', async () => {
    const clientId = randomUUID();
    const created = await createTag('  Family  ', clientId);
    expect(created).toMatchObject({ name: 'Family', clientId, version: 1 });
    expect((await request('POST', '/tags', { clientId, name: 'Family' })).status).toBe(200);
    expect((await request('POST', '/tags', { clientId, name: 'Other' })).status).toBe(409);
    expect((await request('GET', '/tags')).body).toMatchObject({ total: 1, page: 1, pageSize: 50 });
    expect((await request('GET', `/tags/${created.id}`)).body.name).toBe('Family');
    expect((await request('GET', `/tags/${created.id}`, undefined, otherToken)).status).toBe(404);
    expect((await request('PATCH', `/tags/${created.id}`, { version: 1, name: 'Travel' }, otherToken)).status).toBe(404);
    const renamed = await request('PATCH', `/tags/${created.id}`, { version: 1, name: 'Travel' });
    expect(renamed.body).toMatchObject({ name: 'Travel', version: 2 });
    expect((await request('DELETE', `/tags/${created.id}?version=2`, undefined, otherToken)).status).toBe(404);
    expect((await request('DELETE', `/tags/${created.id}?version=2`)).status).toBe(204);
    expect((await request('GET', `/tags/${created.id}`)).status).toBe(404);
    expect(logs).not.toContain('Travel');
    expect(logs).not.toContain('Family');
  });

  it('deleting a linked tag detaches and bumps transaction version', async () => {
    const tag = await createTag('Linked');
    const wallet = await prisma.financialAccount.create({
      data: { userId: owner, clientId: randomUUID(), name: 'Cash', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n },
    });
    const category = await prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Food' } });
    const created = await request('POST', '/transactions', {
      type: 'expense', occurredOn: '2026-09-25', categoryId: category.id, tagIds: [tag.id], merchant: 'WinMart',
      legs: [{ clientId: randomUUID(), accountId: wallet.id, currencyCode: 'VND', amountMinor: '-15000' }],
    });
    expect(created.status).toBe(201);
    expect(created.body.legs[0]).toMatchObject({ tagIds: [tag.id], merchant: 'WinMart', version: 1 });
    expect((await request('DELETE', `/tags/${tag.id}?version=1`)).status).toBe(204);
    const leg = (await request('GET', `/transactions/${created.body.legs[0].id}`)).body.legs[0];
    expect(leg).toMatchObject({ tagIds: [], merchant: 'WinMart', version: 2 });
    expect(await prisma.tag.count({ where: { id: tag.id } })).toBe(0);
    expect(logs).not.toContain('WinMart');
  });

  it('rejects empty name and allows duplicate display names', async () => {
    await createTag('Same');
    expect((await request('POST', '/tags', { clientId: randomUUID(), name: 'Same' })).status).toBe(201);
    expect((await request('POST', '/tags', { clientId: randomUUID(), name: ' ' })).status).toBe(400);
    expect((await request('GET', '/tags', undefined, otherToken)).body.total).toBe(0);
  });
});
