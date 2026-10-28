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
import { BillModule } from '../src/modules/bills/bill.module';
import { CalendarModule } from '../src/modules/calendar/calendar.module';
import { RecurringModule } from '../src/modules/recurring/recurring.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P2-E04 calendar HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
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
        PrismaModule, FinancialAccountModule, TransactionModule, RecurringModule, BillModule, CalendarModule,
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

  async function user(timezone = 'Asia/Ho_Chi_Minh') {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({
      data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND', timezone },
    });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({
      data: {
        userId: id,
        tokenHash: createHash('sha256').update(bearer).digest('hex'),
        expiresAt: new Date(Date.now() + 60000),
      },
    });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user();
    owner = first.id;
    token = first.bearer;
    logs = '';
  });

  afterAll(async () => {
    if (prisma) {
      await prisma.bill.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.recurringOccurrence.deleteMany({ where: { rule: { userId: { in: fixtureUsers } } } });
      await prisma.transactionTag.deleteMany({ where: { transaction: { userId: { in: fixtureUsers } } } });
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.recurringRule.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.fxQuote.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function request(method: string, path: string, body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }

  async function wallet() {
    return prisma.financialAccount.create({
      data: {
        userId: owner,
        clientId: randomUUID(),
        name: 'Cash',
        type: 'cash',
        currencyCode: 'VND',
        initialBalanceMinor: 0n,
      },
    });
  }

  async function category(name = 'Rent') {
    return prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name } });
  }

  it('returns transactions, projected recurring, and bills for the month', async () => {
    const account = await wallet();
    const cat = await category();
    const group = randomUUID();
    await prisma.transaction.createMany({
      data: [
        {
          userId: owner,
          clientId: randomUUID(),
          type: 'expense',
          amountMinor: -120000n,
          currencyCode: 'VND',
          occurredOn: new Date('2026-10-05T00:00:00.000Z'),
          accountId: account.id,
          categoryId: cat.id,
        },
        {
          userId: owner,
          clientId: randomUUID(),
          type: 'transfer',
          amountMinor: -50000n,
          currencyCode: 'VND',
          occurredOn: new Date('2026-10-06T00:00:00.000Z'),
          accountId: account.id,
          transferGroupId: group,
        },
        {
          userId: owner,
          clientId: randomUUID(),
          type: 'transfer',
          amountMinor: 50000n,
          currencyCode: 'VND',
          occurredOn: new Date('2026-10-06T00:00:00.000Z'),
          accountId: account.id,
          transferGroupId: group,
        },
        {
          userId: owner,
          clientId: randomUUID(),
          type: 'expense',
          amountMinor: -1n,
          currencyCode: 'VND',
          occurredOn: new Date('2026-09-30T00:00:00.000Z'),
          accountId: account.id,
          categoryId: cat.id,
        },
      ],
    });
    await prisma.recurringRule.create({
      data: {
        userId: owner,
        clientId: randomUUID(),
        type: 'expense',
        unit: 'month',
        interval: 1,
        amountMinor: -2000000n,
        currencyCode: 'VND',
        accountId: account.id,
        categoryId: cat.id,
        startDate: new Date('2026-01-31T00:00:00.000Z'),
        nextExecutionDate: new Date('2026-10-31T00:00:00.000Z'),
        active: true,
      },
    });
    await prisma.bill.create({
      data: {
        userId: owner,
        clientId: randomUUID(),
        name: 'Internet',
        dueOn: new Date('2026-10-12T00:00:00.000Z'),
        amountMinor: 199000n,
        amountKind: 'fixed',
        currencyCode: 'VND',
      },
    });

    const res = await request('GET', '/calendar?month=2026-10');
    expect(res.status).toBe(200);
    expect(res.body.month).toBe('2026-10');
    expect(res.body.timezone).toBe('Asia/Ho_Chi_Minh');
    expect(res.body.today).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    const dates = res.body.days.map((d: { date: string }) => d.date);
    expect(dates).toEqual(expect.arrayContaining(['2026-10-05', '2026-10-06', '2026-10-12', '2026-10-31']));
    expect(dates).not.toContain('2026-09-30');

    const day6 = res.body.days.find((d: { date: string }) => d.date === '2026-10-06');
    expect(day6.transactions).toHaveLength(1);
    expect(day6.transactions[0].type).toBe('transfer');

    const day31 = res.body.days.find((d: { date: string }) => d.date === '2026-10-31');
    expect(day31.recurring).toHaveLength(1);
    expect(day31.recurring[0].amountMinor).toBe('-2000000');

    const day12 = res.body.days.find((d: { date: string }) => d.date === '2026-10-12');
    expect(day12.bills).toHaveLength(1);
    expect(day12.bills[0].name).toBe('Internet');
    expect(logs).not.toMatch(/199000|-2000000|Internet|120000/);
  });

  it('rejects bad month and hides other owners', async () => {
    const bad = await request('GET', '/calendar?month=2026-13');
    expect(bad.status).toBe(400);
    const missing = await request('GET', '/calendar');
    expect(missing.status).toBe(400);

    const account = await wallet();
    await prisma.transaction.create({
      data: {
        userId: owner,
        clientId: randomUUID(),
        type: 'expense',
        amountMinor: -10n,
        currencyCode: 'VND',
        occurredOn: new Date('2026-10-01T00:00:00.000Z'),
        accountId: account.id,
      },
    });
    const other = await user();
    const foreign = await request('GET', '/calendar?month=2026-10', undefined, other.bearer);
    expect(foreign.status).toBe(200);
    expect(foreign.body.days).toEqual([]);
  });
});
