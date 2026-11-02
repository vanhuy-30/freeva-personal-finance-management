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
import { RecurringModule } from '../src/modules/recurring/recurring.module';
import { RECURRING_REPOSITORY, type RecurringRepository } from '../src/modules/recurring/domain/recurring.repository';
import { BillModule } from '../src/modules/bills/bill.module';
import { SyncModule } from '../src/modules/sync/sync.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';
import { occurrenceClientId } from '../src/modules/recurring/domain/occurrence-id';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P2-E01 recurring HTTP + PostgreSQL', () => {
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
        PrismaModule, FinancialAccountModule, TransactionModule, SyncModule, RecurringModule, BillModule,
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
    logs = '';
  });

  afterAll(async () => {
    if (prisma) {
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

  async function request(method: string, path: string, body?: object, bearer = token, headers: Record<string, string> = {}) {
    const res = await fetch(`${base}/api/v1${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
        ...headers,
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await res.text();
    expect(res.headers.get('cache-control')).toBe('no-store');
    return { status: res.status, body: text ? JSON.parse(text) : undefined };
  }

  async function wallet() {
    return prisma.financialAccount.create({
      data: { userId: owner, clientId: randomUUID(), name: 'Cash', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n },
    });
  }

  async function category() {
    return prisma.category.create({ data: { userId: owner, clientId: randomUUID(), name: 'Rent' } });
  }

  it('creates once on run and stays idempotent on retry and sync', async () => {
    const account = await wallet();
    const cat = await category();
    const clientId = randomUUID();
    const created = await request('POST', '/recurring-transactions', {
      clientId,
      type: 'expense',
      unit: 'month',
      interval: 1,
      amountMinor: '-5000000',
      currencyCode: 'VND',
      accountId: account.id,
      categoryId: cat.id,
      startDate: '2026-01-31',
      nextExecutionDate: '2026-01-31',
    }, token, { 'Idempotency-Key': clientId });
    expect(created.status).toBe(201);
    expect(created.body.nextExecutionDate).toBe('2026-01-31');

    const replay = await request('POST', '/recurring-transactions', {
      clientId,
      type: 'expense',
      unit: 'month',
      interval: 1,
      amountMinor: '-5000000',
      currencyCode: 'VND',
      accountId: account.id,
      categoryId: cat.id,
      startDate: '2026-01-31',
      nextExecutionDate: '2026-01-31',
    }, token, { 'Idempotency-Key': clientId });
    expect(replay.status).toBe(200);

    const repository = app.get<RecurringRepository>(RECURRING_REPOSITORY);
    const asOf = new Date('2026-01-31T12:00:00.000Z');
    const firstRun = await repository.runDue(owner, asOf);
    expect(firstRun.created).toBe(1);
    const countAfterFirst = await prisma.transaction.count({
      where: { userId: owner, recurringRuleId: created.body.id },
    });
    expect(countAfterFirst).toBe(1);

    const secondRun = await repository.runDue(owner, asOf);
    expect(secondRun.created).toBe(0);
    expect(await prisma.transaction.count({
      where: { userId: owner, recurringRuleId: created.body.id },
    })).toBe(1);

    // Push next past wall-clock "today" so HTTP run (Date.now) does not catch up.
    await prisma.recurringRule.update({
      where: { id: created.body.id },
      data: { nextExecutionDate: new Date('2099-01-01T00:00:00.000Z') },
    });
    const httpRun = await request('POST', '/recurring-transactions/run');
    expect(httpRun.status).toBe(200);
    expect(httpRun.body.created).toBe(0);

    const occurrence = await prisma.recurringOccurrence.findFirst({
      where: { ruleId: created.body.id },
      orderBy: { occurredOn: 'asc' },
    });
    expect(occurrence).toBeTruthy();
    const syncClientId = occurrence!.transactionClientId;
    expect(syncClientId).toBe(occurrenceClientId(created.body.id, occurrence!.occurredOn.toISOString().slice(0, 10), 0));

    const sync = await request('POST', '/sync', {
      schemaVersion: 1,
      operations: [{
        opId: syncClientId,
        action: 'create',
        body: {
          type: 'expense',
          occurredOn: occurrence!.occurredOn.toISOString().slice(0, 10),
          categoryId: cat.id,
          legs: [{
            clientId: syncClientId,
            accountId: account.id,
            currencyCode: 'VND',
            amountMinor: '-5000000',
          }],
        },
      }],
    });
    expect(sync.status).toBe(200);
    expect(sync.body.results[0].status).toBe('replayed');
    expect(await prisma.transaction.count({ where: { userId: owner, clientId: syncClientId } })).toBe(1);
    expect(logs).not.toContain('5000000');
  });

  it('does not post when inactive and clamps month without day 31', async () => {
    const account = await wallet();
    const cat = await category();
    const clientId = randomUUID();
    const created = await request('POST', '/recurring-transactions', {
      clientId,
      type: 'expense',
      unit: 'month',
      interval: 1,
      amountMinor: '-100000',
      currencyCode: 'VND',
      accountId: account.id,
      categoryId: cat.id,
      startDate: '2026-01-31',
      nextExecutionDate: '2026-01-31',
      endDate: '2026-03-31',
      active: false,
    }, token, { 'Idempotency-Key': clientId });
    expect(created.status).toBe(201);

    await prisma.recurringRule.update({
      where: { id: created.body.id },
      data: { nextExecutionDate: new Date('2020-01-31T00:00:00.000Z') },
    });
    const inactiveRun = await request('POST', '/recurring-transactions/run');
    expect(inactiveRun.body.created).toBe(0);
    expect(await prisma.transaction.count({ where: { userId: owner, recurringRuleId: created.body.id } })).toBe(0);

    const enabled = await request('PATCH', `/recurring-transactions/${created.body.id}`, {
      version: 1,
      active: true,
      nextExecutionDate: '2026-01-31',
    });
    expect(enabled.status).toBe(200);

    await prisma.recurringRule.update({
      where: { id: created.body.id },
      data: { nextExecutionDate: new Date('2026-01-31T00:00:00.000Z'), active: true, version: enabled.body.version },
    });
    const repository = app.get<RecurringRepository>(RECURRING_REPOSITORY);
    const result = await repository.runDue(owner, new Date('2026-03-15T12:00:00.000Z'));
    expect(result.created).toBe(2);
    const days = (await prisma.transaction.findMany({
      where: { userId: owner, recurringRuleId: created.body.id },
      orderBy: { occurredOn: 'asc' },
      select: { occurredOn: true },
    })).map(row => row.occurredOn.toISOString().slice(0, 10));
    expect(days).toEqual(['2026-01-31', '2026-02-28']);
  });

  it('posts a balanced transfer from a recurring rule', async () => {
    const source = await wallet();
    const destination = await prisma.financialAccount.create({
      data: { userId: owner, clientId: randomUUID(), name: 'Bank', type: 'bank', currencyCode: 'VND', initialBalanceMinor: 0n },
    });
    const clientId = randomUUID();
    const created = await request('POST', '/recurring-transactions', {
      clientId,
      type: 'transfer',
      unit: 'week',
      interval: 1,
      amountMinor: '-200000',
      currencyCode: 'VND',
      accountId: source.id,
      counterAccountId: destination.id,
      counterAmountMinor: '200000',
      counterCurrencyCode: 'VND',
      startDate: '2026-01-05',
      nextExecutionDate: '2026-01-05',
    }, token, { 'Idempotency-Key': clientId });
    expect(created.status).toBe(201);

    const repository = app.get<RecurringRepository>(RECURRING_REPOSITORY);
    const run = await repository.runDue(owner, new Date('2026-01-05T12:00:00.000Z'));
    expect(run.created).toBe(1);
    const legs = await prisma.transaction.findMany({
      where: { userId: owner, recurringRuleId: created.body.id, type: 'transfer' },
      orderBy: { amountMinor: 'asc' },
    });
    expect(legs).toHaveLength(2);
    expect(legs[0].amountMinor + legs[1].amountMinor).toBe(0n);
    expect(legs[0].transferGroupId).toBe(legs[1].transferGroupId);
  });

  describe('BE-P3-001 remind mode (bills)', () => {
    async function bill(extra: object = {}) {
      const clientId = randomUUID();
      const created = await request('POST', '/recurring-transactions', {
        clientId,
        type: 'expense',
        mode: 'remind',
        name: 'Tiền điện',
        amountKind: 'estimated',
        remindDaysBefore: 5,
        repeat: false,
        unit: 'month',
        interval: 1,
        amountMinor: '-850000',
        currencyCode: 'VND',
        startDate: '2026-01-10',
        nextExecutionDate: '2026-01-10',
        ...extra,
      }, token, { 'Idempotency-Key': clientId });
      expect(created.status).toBe(201);
      return created.body;
    }

    it('creates a one-off bill without a wallet; run never posts it; overdue is derived', async () => {
      const created = await bill();
      expect(created).toMatchObject({ mode: 'remind', endDate: '2026-01-10', accountId: null, overdue: true });
      const repository = app.get<RecurringRepository>(RECURRING_REPOSITORY);
      await expect(repository.runDue(owner, new Date('2026-03-01T00:00:00.000Z'))).resolves.toEqual({ created: 0, skipped: 0 });
      expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(0);
    });

    it('rejects a remind rule that is not an expense or has no name', async () => {
      const clientId = randomUUID();
      const noName = await request('POST', '/recurring-transactions', {
        clientId, type: 'expense', mode: 'remind', unit: 'month', interval: 1, amountMinor: '-1000',
        currencyCode: 'VND', startDate: '2026-01-10', nextExecutionDate: '2026-01-10',
      }, token, { 'Idempotency-Key': clientId });
      expect(noName.status).toBe(400);
    });

    it('confirms once: retry and second confirm do not post twice', async () => {
      const account = await wallet();
      const cat = await category();
      const created = await bill({ accountId: account.id, categoryId: cat.id });
      const body = { version: created.version, occurredOn: '2026-01-10', amountMinor: '900000', paidOn: '2026-01-12' };
      const first = await request('POST', `/recurring-transactions/${created.id}/confirm`, body);
      expect(first.status).toBe(200);
      expect(first.body).toMatchObject({ replayed: false, rule: { active: false, overdue: false } });
      const again = await request('POST', `/recurring-transactions/${created.id}/confirm`, body);
      expect(again.status).toBe(200);
      expect(again.body).toMatchObject({ replayed: true, transactionId: first.body.transactionId });
      const posted = await prisma.transaction.findMany({ where: { userId: owner } });
      expect(posted).toHaveLength(1);
      expect(posted[0]).toMatchObject({ amountMinor: -900000n, type: 'expense', recurringRuleId: created.id });
      expect(posted[0].occurredOn.toISOString().slice(0, 10)).toBe('2026-01-12');
      expect(await prisma.recurringOccurrence.count({ where: { ruleId: created.id } })).toBe(1);
      expect(logs).not.toMatch(/900000|850000|Tiền điện/);
    });

    it('links an existing expense, and that expense cannot pay a second bill', async () => {
      const account = await wallet();
      const cat = await category();
      const tx = await prisma.transaction.create({
        data: {
          userId: owner, clientId: randomUUID(), type: 'expense', amountMinor: -850000n, currencyCode: 'VND',
          occurredOn: new Date('2026-01-09T00:00:00.000Z'), accountId: account.id, categoryId: cat.id,
        },
      });
      const one = await bill();
      const two = await bill();
      const linked = await request('POST', `/recurring-transactions/${one.id}/confirm`, {
        version: one.version, occurredOn: '2026-01-10', transactionId: tx.id,
      });
      expect(linked.status).toBe(200);
      expect(linked.body.transactionId).toBe(tx.id);
      expect(await prisma.transaction.count({ where: { userId: owner } })).toBe(1);
      const reuse = await request('POST', `/recurring-transactions/${two.id}/confirm`, {
        version: two.version, occurredOn: '2026-01-10', transactionId: tx.id,
      });
      expect(reuse.status).toBe(409);
    });

    it('advances a repeating bill to the next due day and refuses a wrong day or auto rule', async () => {
      const account = await wallet();
      const cat = await category();
      const monthly = await bill({ repeat: undefined, accountId: account.id, categoryId: cat.id });
      const wrongDay = await request('POST', `/recurring-transactions/${monthly.id}/confirm`, {
        version: monthly.version, occurredOn: '2026-02-10',
      });
      expect(wrongDay.status).toBe(409);
      const ok = await request('POST', `/recurring-transactions/${monthly.id}/confirm`, {
        version: monthly.version, occurredOn: '2026-01-10',
      });
      expect(ok.body.rule).toMatchObject({ active: true, nextExecutionDate: '2026-02-10' });

      const autoId = randomUUID();
      const auto = await request('POST', '/recurring-transactions', {
        clientId: autoId, type: 'expense', unit: 'month', interval: 1, amountMinor: '-1000', currencyCode: 'VND',
        accountId: account.id, categoryId: cat.id, startDate: '2026-01-10', nextExecutionDate: '2026-01-10',
      }, token, { 'Idempotency-Key': autoId });
      const notRemind = await request('POST', `/recurring-transactions/${auto.body.id}/confirm`, {
        version: auto.body.version, occurredOn: '2026-01-10',
      });
      expect(notRemind.status).toBe(400);
    });

    it('answers 410 on every old /bills route', async () => {
      for (const [method, path] of [['GET', '/bills'], ['POST', '/bills'], ['GET', `/bills/${randomUUID()}`], ['POST', `/bills/${randomUUID()}/pay`]]) {
        const res = await request(method, path, method === 'POST' ? {} : undefined);
        expect(res.status).toBe(410);
        expect(res.body.error.code).toBe('BILL_GONE');
      }
    });
  });
});
