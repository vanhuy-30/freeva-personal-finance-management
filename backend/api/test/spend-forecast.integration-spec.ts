import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { SpendForecastModule } from '../src/modules/spend-forecast/spend-forecast.module';
import { SpendForecastService } from '../src/modules/spend-forecast/spend-forecast.service';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P5-E06 spending and goal forecast HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  const users: string[] = [];
  const stream = new Writable({ write(_chunk, _encoding, callback) { callback(); } });
  const now = new Date('2026-11-10T03:00:00Z');

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        LoggerModule.forRoot({ pinoHttp: [{}, stream] }),
        PrismaModule, SpendForecastModule,
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
      await prisma.featureFlag.deleteMany({ where: { key: 'forecast' } });
      await prisma.goalEntry.deleteMany({ where: { userId: { in: users } } });
      await prisma.goal.deleteMany({ where: { userId: { in: users } } });
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
    const food = await prisma.category.create({ data: { userId: id, clientId: randomUUID(), name: 'Ăn uống', kind: 'expense', iconToken: 'food' } });
    const spend = (occurredOn: string, amount: bigint, deletedAt: Date | null = null) => prisma.transaction.create({
      data: { userId: id, accountId: account.id, clientId: randomUUID(), type: 'expense', amountMinor: -amount, currencyCode: 'VND',
        occurredOn: new Date(`${occurredOn}T00:00:00Z`), categoryId: food.id, deletedAt },
    });
    const goal = await prisma.goal.create({ data: {
      userId: id, clientId: randomUUID(), kind: 'home', name: 'Mua nhà', currencyCode: 'VND', targetMinor: 120_000_000n,
      currentMinor: 40_000_000n, targetDate: new Date('2027-08-31T00:00:00Z'), accountId: account.id, icon: 'home',
    } });
    for (const occurredOn of ['2026-08-01', '2026-09-01', '2026-10-01', '2026-11-01']) {
      await prisma.goalEntry.create({ data: { goalId: goal.id, userId: id, clientId: randomUUID(), kind: 'contribute', amountMinor: 5_000_000n, occurredOn: new Date(`${occurredOn}T00:00:00Z`) } });
    }
    const flagOn = () => prisma.featureFlag.upsert({
      where: { key: 'forecast' },
      create: { key: 'forecast', enabled: true, userIds: [id], percentage: 0, updatedBy: randomUUID() },
      update: { enabled: true, userIds: [id], percentage: 0 },
    });
    return { id, bearer, spend, goal, flagOn };
  }

  it('is null while off, then projects live spending and the goal date', async () => {
    const { id, bearer, spend, goal, flagOn } = await setup();
    await spend('2026-10-20', 3_000_000n);
    await spend('2026-11-02', 2_000_000n);
    await spend('2026-11-05', 1_000_000n);
    await spend('2026-11-06', 9_000_000n, new Date());
    const off = await fetch(`${base}/api/v1/spending-forecast`, { headers: { Authorization: `Bearer ${bearer}` } });
    expect(off.status).toBe(200);
    expect((await off.json()).forecast).toBeNull();
    expect((await (await fetch(`${base}/api/v1/goals/${goal.id}/forecast`, { headers: { Authorization: `Bearer ${bearer}` } })).json())).toEqual({ forecast: null });

    await flagOn();
    const service = app.get(SpendForecastService);
    const spending = await service.spending(id, now);
    expect(spending.period).toEqual({ from: '2026-11-01', to: '2026-11-30', today: '2026-11-10' });
    expect(spending.forecast).toMatchObject({ status: 'ok', spentMinor: '3000000', forecastMinor: '9000000', previousMonthMinor: '3000000', risk: null });
    expect(await service.goal(id, goal.id, now)).toEqual({ forecast: {
      status: 'ok', months: 3, averageMonthlyMinor: '5000000', expectedMonth: '2028-02', targetMonth: '2027-08', monthsLate: 6,
    } });
  });

  it('hides other users\' goals and validates the id', async () => {
    const owner = await setup();
    const other = await setup();
    const res = await fetch(`${base}/api/v1/goals/${owner.goal.id}/forecast`, { headers: { Authorization: `Bearer ${other.bearer}` } });
    expect(res.status).toBe(404);
    expect((await fetch(`${base}/api/v1/goals/not-a-uuid/forecast`, { headers: { Authorization: `Bearer ${other.bearer}` } })).status).toBe(400);
    expect((await fetch(`${base}/api/v1/spending-forecast`)).status).toBe(401);
  });
});
