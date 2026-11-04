import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { FinancialAccountModule } from '../src/modules/financial-accounts/financial-account.module';
import { GoalModule } from '../src/modules/goals/goal.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P3-E01 goals HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  let owner: string;
  let token: string;
  const fixtureUsers: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        PrismaModule, FinancialAccountModule, TransactionModule, GoalModule,
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
    await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) },
    });
    return { id, bearer };
  }

  beforeEach(async () => {
    const first = await user();
    owner = first.id;
    token = first.bearer;
  });

  afterAll(async () => {
    if (prisma) {
      const where = { userId: { in: fixtureUsers } };
      await prisma.goalEntry.deleteMany({ where });
      await prisma.goal.deleteMany({ where });
      await prisma.transactionTag.deleteMany({ where: { transaction: where } });
      await prisma.transaction.deleteMany({ where });
      await prisma.financialAccount.deleteMany({ where });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function request(method: string, path: string, body?: object, bearer = token) {
    const res = await fetch(`${base}/api/v1${path}`, {
      method,
      headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }

  const wallet = (userId = owner, currencyCode = 'VND') => prisma.financialAccount.create({
    data: { userId, clientId: randomUUID(), name: 'Wallet', type: 'cash', currencyCode, initialBalanceMinor: 0n },
  });

  function futureDay(months: number): string {
    const date = new Date();
    date.setUTCMonth(date.getUTCMonth() + months);
    return date.toISOString().slice(0, 10);
  }

  async function createGoal(accountId: string, extra: object = {}) {
    const res = await request('POST', '/goals', {
      clientId: randomUUID(), kind: 'home', name: 'Nhà', targetMinor: '120000000', accountId, ...extra,
    });
    expect(res.status).toBe(201);
    return res.body;
  }

  const balance = async (accountId: string) => {
    const sum = await prisma.transaction.aggregate({ where: { accountId, deletedAt: null }, _sum: { amountMinor: true } });
    return sum._sum.amountMinor ?? 0n;
  };

  it('creates with preset icon/colour and replays the same clientId', async () => {
    const account = await wallet();
    const clientId = randomUUID();
    const payload = { clientId, kind: 'travel', name: 'Đà Lạt', targetMinor: '120000000', currentMinor: '40000000', accountId: account.id, targetDate: futureDay(10) };
    const first = await request('POST', '/goals', payload);
    expect(first.status).toBe(201);
    expect(first.body).toMatchObject({ icon: 'travel', currencyCode: 'VND', currentMinor: '40000000', percentBps: 3333, remainingMinor: '80000000', status: 'active' });
    expect(first.body.colorToken).toMatch(/^color\./);
    const replay = await request('POST', '/goals', payload);
    expect(replay.status).toBe(200);
    expect(replay.body.id).toBe(first.body.id);
    expect((await request('POST', '/goals', { ...payload, name: 'Khác' })).status).toBe(409);
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'goal.create' } })).toBe(1);
  });

  it('rejects hex colour, archived or foreign wallets', async () => {
    const account = await wallet();
    const body = { clientId: randomUUID(), kind: 'custom', name: 'X', targetMinor: '100', accountId: account.id };
    expect((await request('POST', '/goals', { ...body, colorToken: '#ff0000' })).status).toBe(400);
    const other = await user();
    const foreign = await wallet(other.id);
    expect((await request('POST', '/goals', { ...body, accountId: foreign.id })).status).toBe(400);
    await prisma.financialAccount.update({ where: { id: account.id }, data: { archivedAt: new Date() } });
    expect((await request('POST', '/goals', body)).status).toBe(400);
  });

  it('contribute from another wallet writes one balanced transfer and is idempotent', async () => {
    const savings = await wallet();
    const spending = await wallet();
    const goal = await createGoal(savings.id);
    const move = { clientId: randomUUID(), amountMinor: '5000000', accountId: spending.id, occurredOn: '2026-11-02' };
    const done = await request('POST', `/goals/${goal.id}/contribute`, move);
    expect(done.status).toBe(201);
    expect(done.body.currentMinor).toBe('5000000');
    expect(await balance(spending.id)).toBe(-5000000n);
    expect(await balance(savings.id)).toBe(5000000n);
    const replay = await request('POST', `/goals/${goal.id}/contribute`, move);
    expect(replay.status).toBe(200);
    expect(replay.body.currentMinor).toBe('5000000');
    expect(await prisma.transaction.count({ where: { userId: owner, type: 'transfer' } })).toBe(2);
    expect((await request('POST', `/goals/${goal.id}/contribute`, { ...move, amountMinor: '1' })).status).toBe(409);
  });

  it('contribute without a source wallet only moves the goal ledger', async () => {
    const savings = await wallet();
    const goal = await createGoal(savings.id);
    const res = await request('POST', `/goals/${goal.id}/contribute`, { clientId: randomUUID(), amountMinor: '1000', occurredOn: '2026-11-02' });
    expect(res.status).toBe(201);
    expect(res.body.currentMinor).toBe('1000');
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
  });

  it('withdraw returns money to a wallet and refuses more than the goal holds', async () => {
    const savings = await wallet();
    const spending = await wallet();
    const goal = await createGoal(savings.id);
    await request('POST', `/goals/${goal.id}/contribute`, { clientId: randomUUID(), amountMinor: '3000', accountId: spending.id, occurredOn: '2026-11-02' });
    const over = await request('POST', `/goals/${goal.id}/withdraw`, { clientId: randomUUID(), amountMinor: '3001', accountId: spending.id, occurredOn: '2026-11-02' });
    expect(over.status).toBe(422);
    expect(over.body.error.code).toBe('INSUFFICIENT_GOAL_BALANCE');
    const ok = await request('POST', `/goals/${goal.id}/withdraw`, { clientId: randomUUID(), amountMinor: '1000', accountId: spending.id, occurredOn: '2026-11-02' });
    expect(ok.status).toBe(201);
    expect(ok.body.currentMinor).toBe('2000');
    expect(await balance(spending.id)).toBe(-2000n);
    expect(await balance(savings.id)).toBe(2000n);
  });

  it('adjust writes an audit line and no transaction; stale version is a conflict', async () => {
    const account = await wallet();
    const goal = await createGoal(account.id);
    const adjusted = await request('POST', `/goals/${goal.id}/adjust`, { currentMinor: '7000', version: goal.version });
    expect(adjusted.status).toBe(200);
    expect(adjusted.body.currentMinor).toBe('7000');
    expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    expect(await prisma.auditEvent.count({ where: { actorId: owner, action: 'goal.adjust', targetId: goal.id } })).toBe(1);
    expect((await request('POST', `/goals/${goal.id}/adjust`, { currentMinor: '8000', version: goal.version })).status).toBe(409);
  });

  it('shows required monthly saving and archives', async () => {
    const account = await wallet();
    const goal = await createGoal(account.id, { currentMinor: '40000000', targetDate: futureDay(10) });
    expect(goal.monthsLeft).toBeGreaterThanOrEqual(10);
    expect(BigInt(goal.requiredPerMonthMinor)).toBeLessThanOrEqual(8000000n);
    const list = await request('GET', '/goals');
    expect(list.body.items).toHaveLength(1);
    expect((await request('DELETE', `/goals/${goal.id}?version=${goal.version}`)).status).toBe(204);
    expect((await request('GET', '/goals')).body.items).toHaveLength(0);
    expect((await request('GET', '/goals?includeArchived=true')).body.items).toHaveLength(1);
    expect((await request('GET', '/goals/presets')).body.items).toHaveLength(8);
  });

  it('lists history newest first: contribute, withdraw and corrected number', async () => {
    const account = await wallet();
    const goal = await createGoal(account.id);
    const day = '2026-11-03';
    await request('POST', `/goals/${goal.id}/contribute`, { clientId: randomUUID(), amountMinor: '5000', occurredOn: day });
    await request('POST', `/goals/${goal.id}/withdraw`, { clientId: randomUUID(), amountMinor: '2000', occurredOn: day });
    const fresh = (await request('GET', `/goals/${goal.id}`)).body;
    expect((await request('POST', `/goals/${goal.id}/adjust`, { currentMinor: '9000', version: fresh.version })).status).toBe(200);
    const res = await request('GET', `/goals/${goal.id}/entries`);
    expect(res.status).toBe(200);
    expect(res.body.items.map((item: { kind: string }) => item.kind).sort()).toEqual(['adjust', 'contribute', 'withdraw']);
    const adjust = res.body.items.find((item: { kind: string }) => item.kind === 'adjust');
    expect(adjust).toMatchObject({ amountMinor: null, transfer: false });
    expect(res.body.items.find((item: { kind: string }) => item.kind === 'contribute')).toMatchObject({ amountMinor: '5000', transfer: false });
    const other = await user();
    expect((await request('GET', `/goals/${goal.id}/entries`, undefined, other.bearer)).status).toBe(404);
  });

  it('does not expose another user goal', async () => {
    const account = await wallet();
    const goal = await createGoal(account.id);
    const other = await user();
    expect((await request('GET', `/goals/${goal.id}`, undefined, other.bearer)).status).toBe(404);
    expect((await request('GET', '/goals', undefined, '')).status).toBe(401);
  });
});
