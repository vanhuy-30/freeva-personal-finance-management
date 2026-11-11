import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { configureHttp } from '../src/core/http/configure-http';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AccountModule } from '../src/modules/account/account.module';
import { AppConfigModule } from '../src/modules/app-config/app-config.module';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { ProfileModule } from '../src/modules/profile/profile.module';
import { TransactionImportModule } from '../src/modules/transaction-import/transaction-import.module';
import { TransactionModule } from '../src/modules/transactions/transaction.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P5-E08 app config HTTP + PostgreSQL', () => {
  const staffToken = randomBytes(32).toString('hex');
  const staffActorId = randomUUID();
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  const fixtureUsers: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
          STAFF_AUTH_TOKEN: staffToken, STAFF_ACTOR_ID: staffActorId,
        })] }),
        PrismaModule, AppConfigModule, AccountModule, TransactionModule, TransactionImportModule, ProfileModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    configureHttp(app);
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    await app.get(AuthMailWorker).onModuleDestroy();
  });

  async function cleanConfig() {
    await prisma.featureFlag.deleteMany();
    await prisma.appConfigValue.deleteMany();
    await prisma.appConfigChange.deleteMany({ where: { actorId: staffActorId } });
    await prisma.auditEvent.deleteMany({ where: { actorId: staffActorId } });
  }

  beforeEach(cleanConfig);

  afterAll(async () => {
    if (prisma) {
      await cleanConfig();
      await prisma.transactionTag.deleteMany({ where: { transaction: { userId: { in: fixtureUsers } } } });
      await prisma.transaction.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.importBatch.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.tag.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.category.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.financialAccount.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.auditEvent.deleteMany({ where: { actorId: { in: fixtureUsers } } });
      await prisma.authSession.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });

  async function user() {
    const id = randomUUID();
    fixtureUsers.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) },
    });
    return { id, bearer };
  }

  async function call(method: string, path: string, bearer: string, body?: unknown, extra: Record<string, string> = {}) {
    const response = await fetch(`${base}/api${path}`, {
      method,
      headers: { authorization: `Bearer ${bearer}`, ...(body === undefined ? {} : { 'content-type': 'application/json' }), ...extra },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await response.text();
    return { status: response.status, cache: response.headers.get('cache-control'), body: text ? JSON.parse(text) : undefined };
  }

  it('gives a user code defaults and every flag off on an empty store', async () => {
    const { bearer } = await user();
    const result = await call('GET', '/v1/app-config', bearer);
    expect(result.status).toBe(200);
    expect(result.cache).toBe('no-store');
    expect(Object.values(result.body.flags).every((on) => on === false)).toBe(true);
    expect(result.body.config['budget.defaultAlertThresholds']).toEqual([80, 100]);
    expect(result.body.config['onboarding.incomeSuggestionsVnd']).toEqual(['10000000', '15000000', '25000000', '40000000']);
    expect(typeof result.body.version).toBe('number');
  });

  it('requires a user session and a staff token on the right routes', async () => {
    const { bearer } = await user();
    expect((await call('GET', '/v1/app-config', 'f'.repeat(64))).status).toBe(401);
    expect((await call('GET', '/admin/app-config', bearer)).status).toBe(401);
    expect((await call('PUT', '/admin/app-config/values/report.topRows', bearer, { value: 4, version: 0 })).status).toBe(401);
    expect(await prisma.appConfigValue.count()).toBe(0);
  });

  it('turns a flag on for listed users only and audits the change', async () => {
    const listed = await user();
    const other = await user();
    const before = (await call('GET', '/v1/app-config', listed.bearer)).body.version;
    const saved = await call('PUT', '/admin/app-config/flags/insights', staffToken, {
      enabled: true, userIds: [listed.id], percentage: 0, version: 0,
    });
    expect(saved.status).toBe(200);
    const flag = saved.body.flags.find((row: { key: string }) => row.key === 'insights');
    expect(flag).toMatchObject({ enabled: true, userIds: [listed.id], percentage: 0, version: 1 });
    expect(flag.lastChange.updatedBy).toBe(staffActorId);

    const mine = (await call('GET', '/v1/app-config', listed.bearer)).body;
    expect(mine.flags.insights).toBe(true);
    expect(mine.version).toBe(before + 1);
    expect((await call('GET', '/v1/app-config', other.bearer)).body.flags.insights).toBe(false);

    const change = await prisma.appConfigChange.findFirstOrThrow({ where: { key: 'insights' } });
    expect(change).toMatchObject({ kind: 'flag', actorId: staffActorId, before: null });
    expect(change.after).toEqual({ enabled: true, userIds: [listed.id], percentage: 0 });
    expect(await prisma.auditEvent.count({
      where: { actorType: 'staff', actorId: staffActorId, action: 'staff.app_config_update', targetType: 'app_config', outcome: 'success' },
    })).toBe(1);
  });

  it('saves, conflicts on a stale version without writing, and resets a value', async () => {
    const { bearer } = await user();
    const first = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [1, 3, 6], version: 0 });
    expect(first.status).toBe(200);
    expect((await call('GET', '/v1/app-config', bearer)).body.config['forecast.monthOptions']).toEqual([1, 3, 6]);

    const stale = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [3, 6], version: 0 });
    expect(stale.status).toBe(409);
    expect(stale.body.error.code).toBe('CONFIG_CONFLICT');
    expect(await prisma.appConfigChange.count({ where: { key: 'forecast.monthOptions' } })).toBe(1);

    const second = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [3, 6], version: 1 });
    expect(second.status).toBe(200);
    const row = second.body.config.find((entry: { key: string }) => entry.key === 'forecast.monthOptions');
    expect(row).toMatchObject({ value: [3, 6], isDefault: false, version: 2 });

    expect((await call('DELETE', '/admin/app-config/values/forecast.monthOptions?version=1', staffToken)).status).toBe(409);
    const reset = await call('DELETE', '/admin/app-config/values/forecast.monthOptions?version=2', staffToken);
    expect(reset.status).toBe(200);
    expect((await call('GET', '/v1/app-config', bearer)).body.config['forecast.monthOptions']).toEqual([3, 6, 12]);
    const changes = await prisma.appConfigChange.findMany({ where: { key: 'forecast.monthOptions' }, orderBy: { occurredAt: 'asc' } });
    expect(changes.map((change) => change.after)).toEqual([[1, 3, 6], [3, 6], null]);
    expect(await prisma.auditEvent.count({ where: { actorId: staffActorId, action: 'staff.app_config_update' } })).toBe(3);
  });

  it('rejects bad values and unknown keys', async () => {
    const bad = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [6, 3], version: 0 });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toMatchObject({ code: 'CONFIG_VALUE_INVALID' });
    expect(bad.body.error.details[0].reason).toContain('ascending');
    expect((await call('PUT', '/admin/app-config/values/import.maxRows', staffToken, { value: 5000, version: 0 })).status).toBe(400);
    expect((await call('PUT', '/admin/app-config/flags/insights', staffToken, {
      enabled: true, userIds: ['nope'], percentage: 0, version: 0,
    })).status).toBe(400);
    const unknown = await call('PUT', '/admin/app-config/values/nope.key', staffToken, { value: 1, version: 0 });
    expect(unknown.status).toBe(404);
    expect(unknown.body.error.code).toBe('CONFIG_KEY_UNKNOWN');
    expect(await prisma.appConfigValue.count()).toBe(0);
    expect(await prisma.featureFlag.count()).toBe(0);
  });

  it('removes a deleted account from flag allow-lists', async () => {
    const leaving = await user();
    const staying = await user();
    await call('PUT', '/admin/app-config/flags/forecast', staffToken, {
      enabled: true, userIds: [leaving.id, staying.id], percentage: 0, version: 0,
    });
    expect((await call('DELETE', '/v1/account', leaving.bearer)).status).toBe(204);
    const flag = await prisma.featureFlag.findUniqueOrThrow({ where: { key: 'forecast' } });
    expect(flag.userIds).toEqual([staying.id].sort());
    expect(flag.version).toBe(2);
  });

  it('BE-P5-001 keeps read-only limits fixed and lists them for the app', async () => {
    const { bearer } = await user();
    const config = (await call('GET', '/v1/app-config', bearer)).body.config;
    expect(config['limit.passwordMaxLength']).toBe(128);
    const readonly = await call('PUT', '/admin/app-config/values/limit.passwordMaxLength', staffToken, { value: 128, version: 0 });
    expect(readonly.status).toBe(400);
    expect(readonly.body.error.code).toBe('CONFIG_KEY_READONLY');
    const crossed = await call('PUT', '/admin/app-config/values/installment.defaultTerm', staffToken, { value: 24, version: 0 });
    expect(crossed.status).toBe(400);
    expect(crossed.body.error.details[0].reason).toContain('installment.termOptions');
    expect(await prisma.appConfigValue.count()).toBe(0);
  });

  it('BE-P5-001 the API enforces limits staff lowered', async () => {
    const { id, bearer } = await user();
    const wallet = await prisma.financialAccount.create({
      data: { userId: id, clientId: randomUUID(), name: 'Tiền mặt', type: 'cash', currencyCode: 'VND', initialBalanceMinor: 0n },
    });
    const tags = await Promise.all([1, 2, 3].map((n) => prisma.tag.create({ data: { userId: id, clientId: randomUUID(), name: `T${n}` } })));
    const create = (tagIds: string[]) => {
      const clientId = randomUUID();
      const body = { type: 'income', occurredOn: '2026-11-01', tagIds, legs: [{ clientId, accountId: wallet.id, currencyCode: 'VND', amountMinor: '1000' }] };
      return call('POST', '/v1/transactions', bearer, body, { 'idempotency-key': clientId });
    };
    expect((await create(tags.map((t) => t.id))).status).toBe(201);
    expect((await call('PUT', '/admin/app-config/values/transaction.maxTags', staffToken, { value: 2, version: 0 })).status).toBe(200);
    const tooMany = await create(tags.map((t) => t.id));
    expect(tooMany.status).toBe(400);
    expect((await create([tags[0].id, tags[1].id])).status).toBe(201);

    const header = 'date,time,type,amount,currency,wallet,category,merchant,notes,tags,transaction_id\r\n';
    const line = '2026-10-06,,income,5000,VND,Tiền mặt,,,,,\r\n';
    const text = header + line.repeat(3);
    expect((await call('POST', '/v1/transactions/import/preview', bearer, { text })).status).toBe(200);
    expect((await call('PUT', '/admin/app-config/values/import.maxRows', staffToken, { value: 2, version: 0 })).status).toBe(200);
    const big = await call('POST', '/v1/transactions/import/preview', bearer, { text });
    expect(big.status).toBe(413);
    expect(big.body.error.code).toBe('FILE_TOO_LARGE');
  });

  it('BE-P5-001 profile options carry the currency symbol', async () => {
    const { bearer } = await user();
    const options = await call('GET', '/v1/profile/options', bearer);
    expect(options.body.currencies).toContainEqual({ code: 'VND', minorDigits: 0, symbol: '₫' });
  });
});
