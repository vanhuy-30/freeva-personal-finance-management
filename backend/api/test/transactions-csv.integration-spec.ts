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


describe('BE-P3-010 transactions CSV export HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let token: string;
  let otherOwner: string;
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
    owner = first.id; token = first.bearer; otherOwner = second.id; otherToken = second.bearer;
  });
  afterAll(async () => {
    if (prisma) {
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  const get = (path: string, bearer = token) => fetch(`${base}/api${path}`, { headers: { Authorization: `Bearer ${bearer}` } });
  const wallet = (ownerId: string, name: string) => prisma.financialAccount.create({
    data: { userId: ownerId, clientId: randomUUID(), name, type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n } });
  async function spend(ownerId: string, bearer: string, accountId: string, amount: bigint, occurredOn: string, extra: object = {}) {
    const clientId = randomUUID();
    const category = await prisma.category.create({ data: { userId: ownerId, clientId: randomUUID(), name: 'Ăn uống', kind: 'expense' } });
    const res = await fetch(`${base}/api/v1/transactions`, { method: 'POST',
      headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json', 'Idempotency-Key': clientId },
      body: JSON.stringify({ type: 'expense', occurredOn, categoryId: category.id, legs: [{ clientId, accountId, currencyCode: 'VND', amountMinor: (-amount).toString() }], ...extra }) });
    expect(res.status).toBe(201);
    return ownerId;
  }

  it('exports filtered rows as UTF-8 CSV with BOM, safe cells and an audit row', async () => {
    const a = await wallet(owner, 'Ví, chính'); const b = await wallet(owner, 'Ví phụ');
    await spend(owner, token, a.id, 50000n, '2026-10-05', { notes: '=cmd|"x"', merchant: 'Cà phê "Phố"' });
    await spend(owner, token, a.id, 70000n, '2026-10-20');
    await spend(owner, token, b.id, 90000n, '2026-10-21');
    const res = await get(`/v1/transactions/export.csv?from=2026-10-10&to=2026-10-31&accountId=${a.id}`);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toContain('text/csv');
    expect(res.headers.get('content-disposition')).toMatch(/^attachment; filename="freeva-transactions-\d{8}\.csv"$/);
    expect(res.headers.get('cache-control')).toBe('no-store');
    const bytes = new Uint8Array(await res.arrayBuffer());
    expect([...bytes.slice(0, 3)]).toEqual([0xef, 0xbb, 0xbf]);
    const text = new TextDecoder('utf-8', { ignoreBOM: true }).decode(bytes);
    expect(text.startsWith('\uFEFFdate,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n')).toBe(true);
    const lines = text.trimEnd().split('\r\n');
    expect(lines).toHaveLength(2);
    expect(lines[1]).toMatch(/^2026-10-20,,expense,-70000,VND,"Ví, chính",Ăn uống,,,,[0-9a-f-]{36}$/);
    const all = await (await get(`/v1/transactions/export.csv?accountId=${a.id}`)).text();
    expect(all).toContain(`'=cmd|""x""`);
    expect(all).toContain('"Cà phê ""Phố"""');
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'user.transactions_export' } })).toBe(2);
  });

  it('never includes another user\'s rows and rejects bad filters', async () => {
    const mine = await wallet(owner, 'Của tôi'); const theirs = await wallet(otherOwner, 'Của người khác');
    await spend(owner, token, mine.id, 1000n, '2026-10-05');
    await spend(otherOwner, otherToken, theirs.id, 2000n, '2026-10-05');
    const text = await (await get('/v1/transactions/export.csv')).text();
    expect(text).toContain('Của tôi');
    expect(text).not.toContain('Của người khác');
    expect((await get('/v1/transactions/export.csv?from=2026-10-31&to=2026-10-01')).status).toBe(400);
    expect((await get('/v1/transactions/export.csv?from=nope')).status).toBe(400);
    expect((await fetch(`${base}/api/v1/transactions/export.csv`)).status).toBe(401);
  });
});
