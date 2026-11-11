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
        PrismaModule, AppConfigModule, AccountModule,
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

  async function call(method: string, path: string, bearer: string, body?: unknown) {
    const response = await fetch(`${base}/api${path}`, {
      method,
      headers: { authorization: `Bearer ${bearer}`, ...(body === undefined ? {} : { 'content-type': 'application/json' }) },
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

    const stale = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [6], version: 0 });
    expect(stale.status).toBe(409);
    expect(stale.body.error.code).toBe('CONFIG_CONFLICT');
    expect(await prisma.appConfigChange.count({ where: { key: 'forecast.monthOptions' } })).toBe(1);

    const second = await call('PUT', '/admin/app-config/values/forecast.monthOptions', staffToken, { value: [6], version: 1 });
    expect(second.status).toBe(200);
    const row = second.body.config.find((entry: { key: string }) => entry.key === 'forecast.monthOptions');
    expect(row).toMatchObject({ value: [6], isDefault: false, version: 2 });

    expect((await call('DELETE', '/admin/app-config/values/forecast.monthOptions?version=1', staffToken)).status).toBe(409);
    const reset = await call('DELETE', '/admin/app-config/values/forecast.monthOptions?version=2', staffToken);
    expect(reset.status).toBe(200);
    expect((await call('GET', '/v1/app-config', bearer)).body.config['forecast.monthOptions']).toEqual([3, 6, 12]);
    const changes = await prisma.appConfigChange.findMany({ where: { key: 'forecast.monthOptions' }, orderBy: { occurredAt: 'asc' } });
    expect(changes.map((change) => change.after)).toEqual([[1, 3, 6], [6], null]);
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
});
