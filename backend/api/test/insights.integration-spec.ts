import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { InsightModule } from '../src/modules/insights/insight.module';
import { InsightService } from '../src/modules/insights/insight.service';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P5-E04 insights HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  const users: string[] = [];
  const stream = new Writable({ write(_chunk, _encoding, callback) { callback(); } });

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{}, stream] }),
        PrismaModule, InsightModule,
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

  afterAll(async () => {
    if (prisma) {
      await prisma.featureFlag.deleteMany({ where: { key: 'insights' } });
      await prisma.transaction.deleteMany({ where: { userId: { in: users } } });
      await prisma.category.deleteMany({ where: { userId: { in: users } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: users } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: users } } });
      await prisma.user.deleteMany({ where: { id: { in: users } } });
    }
    await app?.close();
  });

  async function setup() {
    const id = randomUUID();
    users.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone: 'Asia/Ho_Chi_Minh' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) } });
    const account = await prisma.financialAccount.create({ data: { userId: id, clientId: randomUUID(), name: 'Ví', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n } });
    await prisma.currency.upsert({ where: { code: 'USD' }, create: { code: 'USD', minorDigits: 2, name: 'US Dollar' }, update: {} });
    const usd = await prisma.financialAccount.create({ data: { userId: id, clientId: randomUUID(), name: 'USD', type: 'cash', currencyCode: 'USD', initialBalanceMinor: 0n } });
    const food = await prisma.category.create({ data: { userId: id, clientId: randomUUID(), name: 'Ăn uống', kind: 'expense', iconToken: 'food' } });
    const spend = (occurredOn: string, amount: bigint, accountId = account.id, deletedAt: Date | null = null) => prisma.transaction.create({
      data: { userId: id, accountId, clientId: randomUUID(), type: 'expense', amountMinor: -amount, currencyCode: accountId === usd.id ? 'USD' : 'VND',
        occurredOn: new Date(`${occurredOn}T00:00:00Z`), categoryId: food.id, deletedAt },
    });
    return { id, bearer, food, usd, spend };
  }
  const get = (bearer: string) => fetch(`${base}/api/v1/insights`, { headers: { Authorization: `Bearer ${bearer}` } });

  it('is empty while the flag is off, then reports from live transactions in the profile currency only', async () => {
    const { id, bearer, food, usd, spend } = await setup();
    await spend('2026-09-04', 1_000_000n);
    await spend('2026-10-04', 1_000_000n);
    await spend('2026-11-03', 1_500_000n);
    await spend('2026-11-04', 9_000_000n, usd.id);
    await spend('2026-11-05', 9_000_000n, undefined, new Date());
    const off = await get(bearer);
    expect(off.status).toBe(200);
    expect(off.headers.get('cache-control')).toBe('no-store');
    expect((await off.json()).items).toEqual([]);

    await prisma.featureFlag.upsert({
      where: { key: 'insights' },
      create: { key: 'insights', enabled: true, userIds: [id], percentage: 0, updatedBy: randomUUID() },
      update: { enabled: true, userIds: [id], percentage: 0 },
    });
    const result = await app.get(InsightService).list(id, new Date('2026-11-10T03:00:00Z'));
    expect(result.period).toEqual({ from: '2026-11-01', to: '2026-11-30', today: '2026-11-10' });
    expect(result.items).toEqual([
      { kind: 'category_change', category: { id: food.id, name: 'Ăn uống', iconToken: 'food', colorToken: null },
        currentMinor: '1500000', previousMinor: '1000000', changePercent: 50, direction: 'up' },
      { kind: 'spend_trend', currentMinor: '1500000', previousMinor: '1000000', changePercent: 50, direction: 'up', days: 10 },
    ]);

    await prisma.user.update({ where: { id }, data: { autoSuggestEnabled: false } });
    expect((await app.get(InsightService).list(id, new Date('2026-11-10T03:00:00Z'))).items).toEqual([]);
  });

  it('requires a session', async () => {
    expect((await fetch(`${base}/api/v1/insights`)).status).toBe(401);
  });
});
