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
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { FxRateModule } from '../src/modules/fx-rates/fx-rate.module';
import { ProfileModule } from '../src/modules/profile/profile.module';
import { ReportModule } from '../src/modules/reports/report.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P2-013 display conversion HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
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
        PrismaModule, FxRateModule, ReportModule, FinancialAccountModule, ProfileModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
    for (const currency of [
      { code: 'VND', minorDigits: 0, name: 'Dong' },
      { code: 'USD', minorDigits: 2, name: 'US Dollar' },
      { code: 'JPY', minorDigits: 0, name: 'Yen' },
    ]) await prisma.currency.upsert({ where: { code: currency.code }, create: currency, update: {} });
  });

  async function user() {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) } });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user();
    const second = await user();
    owner = first.id; token = first.bearer; otherToken = second.bearer;
    logs = '';
  });

  afterAll(async () => {
    if (prisma) {
      await prisma.userFxRate.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function call(method: string, path: string, body?: object, bearer: string | null = token) {
    const res = await fetch(`${base}/api/v1/${path}`, {
      method, headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    return { status: res.status, body: text ? JSON.parse(text) : null };
  }
  const wallet = (currencyCode: string, initialBalanceMinor: bigint) =>
    prisma.financialAccount.create({ data: { userId: owner, clientId: randomUUID(), name: 'Wallet', type: 'cash', currencyCode, initialBalanceMinor } });

  it('requires auth and keeps one rate per direction, per user', async () => {
    expect((await call('GET', 'fx-rates', undefined, null)).status).toBe(401);
    const quotedAt = '2026-10-30T02:00:00.000Z';
    expect((await call('PUT', 'fx-rates/USD/VND', { rate: '25000', quotedAt })).body).toEqual({ fromCode: 'USD', toCode: 'VND', rate: '25000.00000000', quotedAt });
    expect((await call('PUT', 'fx-rates/USD/VND', { rate: '25500.5', quotedAt })).body.rate).toBe('25500.50000000');
    expect((await call('GET', 'fx-rates')).body.items).toHaveLength(1);
    expect((await call('GET', 'fx-rates', undefined, otherToken)).body.items).toEqual([]);
    expect((await call('DELETE', 'fx-rates/USD/VND', undefined, otherToken)).status).toBe(404);
    expect((await call('DELETE', 'fx-rates/USD/VND')).status).toBe(204);
    expect((await call('DELETE', 'fx-rates/USD/VND')).status).toBe(404);
  });

  it.each([
    ['USD/VND', { rate: '0' }], ['USD/VND', { rate: '-1' }], ['USD/VND', { rate: '1e3' }], ['USD/VND', { rate: 25000 }],
    ['USD/VND', { rate: '1.123456789' }], ['USD/USD', { rate: '1' }], ['USD/XXX', { rate: '1' }], ['usd/VND', { rate: '1' }],
    ['USD/VND', { rate: '1', quotedAt: '2999-01-01T00:00:00.000Z' }], ['USD/VND', { rate: '1', extra: true }],
  ])('rejects %s %j', async (pair, body) => {
    expect((await call('PUT', `fx-rates/${pair}`, body)).status).toBe(400);
    expect(await prisma.userFxRate.count({ where: { userId: owner } })).toBe(0);
  });

  it('adds net worth in the display currency, leaves unconvertible wallets out, and logs no amounts', async () => {
    await wallet('VND', 10_000_000n);
    await wallet('USD', 123_456n);
    await wallet('JPY', 3n);
    await call('PUT', 'fx-rates/USD/VND', { rate: '25000' });
    await call('PUT', 'fx-rates/JPY/VND', { rate: '170.5' });
    const report = await call('GET', 'reports/net-worth?displayCurrency=VND');
    expect(report.status).toBe(200);
    expect(report.body.items).toHaveLength(3);
    expect(report.body.converted).toEqual({
      currency: 'VND', assetsMinor: '40864000', liabilitiesMinor: '0', netWorthMinor: '40864000',
      unconverted: [{ currency: 'JPY', reason: 'FRACTIONAL' }],
    });
    expect((await call('GET', 'reports/net-worth')).body.converted).toBeUndefined();
    expect((await call('GET', 'reports/net-worth?displayCurrency=vnd')).status).toBe(400);
    expect((await call('GET', 'reports/cashflow?period=month&displayCurrency=VND')).body.converted).toMatchObject({ currency: 'VND', incomeMinor: '0', expenseMinor: '0' });
    for (const secret of ['40864000', '123456', '10000000']) expect(logs).not.toContain(secret);
  });

  it('shows the wallet balance in the profile currency with rate and quotedAt, and never stores it', async () => {
    const usd = await wallet('USD', 1_234n);
    const vnd = await wallet('VND', 500n);
    expect((await call('GET', `financial-accounts/${usd.id}`)).body.converted).toBeNull();
    const quotedAt = '2026-10-30T02:00:00.000Z';
    await call('PUT', 'fx-rates/USD/VND', { rate: '25000', quotedAt });
    const detail = await call('GET', `financial-accounts/${usd.id}`);
    expect(detail.body).toMatchObject({ currencyCode: 'USD', balanceMinor: '1234', converted: { currencyCode: 'VND', amountMinor: '308500', rate: '25000.00000000', quotedAt } });
    expect((await call('GET', `financial-accounts/${vnd.id}`)).body.converted).toBeNull();
    expect((await prisma.financialAccount.findUnique({ where: { id: usd.id } }))?.initialBalanceMinor).toBe(1234n);
  });

  it('stores the display currency on the account', async () => {
    expect((await call('PUT', 'profile/display-currency', { currencyCode: 'USD' })).status).toBe(204);
    expect((await call('GET', 'profile')).body.displayCurrencyCode).toBe('USD');
    expect((await call('PUT', 'profile/display-currency', { currencyCode: 'XXX' })).status).toBe(400);
    expect((await call('PUT', 'profile/display-currency', { currencyCode: null })).status).toBe(204);
    expect((await call('GET', 'profile')).body.displayCurrencyCode).toBeNull();
  });
});
