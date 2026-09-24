import { ProfileModule } from '../src/modules/profile/profile.module';
import { randomBytes } from 'node:crypto';
import { Test } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthModule } from '../src/modules/auth/auth.module';
import { AUTH_REPOSITORY } from '../src/modules/auth/domain/auth.repository';
import { AuthService } from '../src/modules/auth/auth.service';
import { AuthCrypto } from '../src/modules/auth/infrastructure/auth-crypto';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { PrismaAuthRepository } from '../src/modules/auth/infrastructure/prisma-auth.repository';

const sendMail = jest.fn().mockImplementation(async (message: { to: string }) => ({
  accepted: [message.to], rejected: [],
}));
jest.mock('nodemailer', () => ({
  createTransport: () => ({ sendMail, close: jest.fn() }),
}));

// Explicit opt-in, never use the developer's .env database.
const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error(
    'AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test',
  );
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P1-001 / BE-P1-002 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let crypto: AuthCrypto;
  let repository: PrismaAuthRepository;
  let auth: AuthService;
  let worker: AuthMailWorker;
  let base: string;
  const password = 'correct horse battery staple';

  it('MOB-P1-001 email-step normalizes, limits, and exposes only routing', async () => {
    const email = 'entry@example.test';
    const fresh = await request('auth/email-step', { email: ' Entry@Example.test ' });
    expect(fresh.status).toBe(200);
    expect(fresh.headers.get('cache-control')).toBe('no-store');
    expect(fresh.body).toEqual({ nextStep: 'register' });
    await auth.register(email, password);
    const existing = await request('auth/email-step', { email });
    expect(existing.body).toEqual({ nextStep: 'login' });
    for (let attempt = 0; attempt < 3; attempt++) {
      expect((await request('auth/email-step', { email })).status).toBe(200);
    }
    const limited = await request('auth/email-step', { email });
    expect(limited.status).toBe(429);
    expect(Number(limited.headers.get('retry-after'))).toBeGreaterThan(0);
    expect((await request('auth/email-step', { email: 'invalid' })).status).toBe(400);
  });

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          ignoreEnvFile: true,
          isGlobal: true,
          load: [
            () => ({
              AUTH_SECRET_KEY: randomBytes(32).toString('hex'),
              NODE_ENV: 'test',
              MAIL_PROVIDER: 'smtp',
              SMTP_HOST: 'localhost',
              SMTP_FROM: 'noreply@example.test',
              SMTP_PORT: '1025',
            }),
          ],
        }),
        PrismaModule,
        AuthModule,
        ProfileModule,
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
    prisma = app.get(PrismaService);
    crypto = app.get(AuthCrypto);
    auth = app.get(AuthService);
    worker = app.get(AuthMailWorker);
    repository = new PrismaAuthRepository(prisma);
    // Delivery is explicitly driven by tests to make lease/retry assertions deterministic.
    await worker.onModuleDestroy();
  });

  afterAll(async () => {
    await app?.close();
  });
  beforeEach(async () => {
    await prisma.auditEvent.deleteMany();
    await prisma.authRateLimit.deleteMany();
    await prisma.authMailJob.deleteMany();
    await prisma.authToken.deleteMany();
    await prisma.authSession.deleteMany();
    await prisma.user.deleteMany();
    sendMail.mockClear();
  });

  async function request(
    path: string,
    body?: object,
    bearer?: string,
    method = 'POST',
  ) {
    const response = await fetch(`${base}/api/v1/${path}`, {
      method,
      headers: {
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
    const text = await response.text();
    return {
      status: response.status,
      body: text ? JSON.parse(text) : undefined,
      headers: response.headers,
    };
  }
  async function emailToken(
    email: string,
    purpose: 'verify_email' | 'reset_password',
  ) {
    const user = await prisma.user.findUniqueOrThrow({ where: { email } });
    const job = await prisma.authMailJob.findUniqueOrThrow({
      where: { userId_purpose: { userId: user.id, purpose } },
    });
    return crypto.decrypt(job.encryptedToken);
  }
  async function verified(email = 'owner@example.test') {
    expect((await request('auth/register', { email, password })).status).toBe(
      202,
    );
    expect(
      (
        await request('auth/verify-email', {
          token: await emailToken(email, 'verify_email'),
        })
      ).status,
    ).toBe(204);
    const login = await request('auth/login', { email, password });
    expect(login.status).toBe(200);
    return login.body as { accessToken: string; sessionId: string };
  }

  it('MOB-P1-002 persists own profile, increments version, and rejects concurrent stale writes', async () => {
    const owner = await verified('profile-owner@example.test');
    const other = await verified('profile-other@example.test');
    await prisma.currency.upsert({ where: { code: 'USD' }, update: {},
      create: { code: 'USD', minorDigits: 2, name: 'US Dollar' } });
    const current = await request('profile', undefined, owner.accessToken, 'GET');
    expect(current.status).toBe(200);
    const changes = { ...current.body, locale: 'en', defaultCurrencyCode: 'USD',
      timezone: 'America/New_York', fiscalMonthStartDay: 28 };
    const writes = await Promise.all([
      request('profile', changes, owner.accessToken, 'PUT'),
      request('profile', changes, owner.accessToken, 'PUT'),
    ]);
    expect(writes.map(r => r.status).sort()).toEqual([200, 409]);
    expect((await request('profile', undefined, owner.accessToken, 'GET')).body)
      .toEqual({ ...changes, version: current.body.version + 1 });
    expect((await request('profile', undefined, other.accessToken, 'GET')).body)
      .toMatchObject({ locale: 'vi', defaultCurrencyCode: 'VND', fiscalMonthStartDay: 1 });
    await request('auth/logout', undefined, owner.accessToken);
    expect((await request('profile', undefined, owner.accessToken, 'GET')).status).toBe(401);
    expect((await request('profile', { ...changes, version: current.body.version + 1 }, owner.accessToken, 'PUT')).status).toBe(401);
  });

  it('normalizes email, hashes passwords/tokens, verifies once, lists and logs out', async () => {
    expect(
      (
        await request('auth/register', {
          email: ' Owner@Example.Test ',
          password,
        })
      ).status,
    ).toBe(202);
    const user = await prisma.user.findUniqueOrThrow({
      where: { email: 'owner@example.test' },
    });
    expect(user.passwordHash).toMatch(/^\$argon2id\$/);
    expect(user.defaultCurrencyCode).toBe('VND');
    const unverifiedLogin = await request('auth/login', {
      email: user.email,
      password,
    });
    expect(unverifiedLogin.status).toBe(200);
    expect(
      (
        await request(
          'sessions',
          undefined,
          unverifiedLogin.body.accessToken,
          'GET',
        )
      ).status,
    ).toBe(200);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { id: user.id } }))
        .emailVerifiedAt,
    ).toBeNull();
    expect(
      (
        await request('auth/login', {
          email: user.email,
          password: 'incorrect password',
        })
      ).status,
    ).toBe(401);
    expect(
      (
        await request(
          'auth/logout',
          undefined,
          unverifiedLogin.body.accessToken,
        )
      ).status,
    ).toBe(204);
    const token = await emailToken(user.email, 'verify_email');
    expect((await prisma.authToken.findFirstOrThrow()).tokenHash).not.toBe(
      token,
    );
    await worker.flush();
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: user.email,
        text: expect.stringContaining(token),
      }),
    );
    expect(await prisma.authMailJob.count()).toBe(0);
    expect((await request('auth/verify-email', { token })).status).toBe(204);
    expect((await request('auth/verify-email', { token })).status).toBe(400);
    const login = await request('auth/login', { email: user.email, password });
    expect(login.status).toBe(200);
    expect(login.headers.get('cache-control')).toBe('no-store');
    expect((await prisma.authSession.findFirstOrThrow()).tokenHash).not.toBe(
      login.body.accessToken,
    );
    const list = await request(
      'sessions',
      undefined,
      login.body.accessToken,
      'GET',
    );
    expect(list.body.sessions).toEqual([
      expect.objectContaining({ id: login.body.sessionId, current: true }),
    ]);
    expect(list.body.sessions[0]).not.toHaveProperty('tokenHash');
    expect(
      (await request('auth/logout', undefined, login.body.accessToken)).status,
    ).toBe(204);
    expect(
      (await request('sessions', undefined, login.body.accessToken, 'GET'))
        .status,
    ).toBe(401);
  });

  it('does not overwrite duplicate registration and returns generic responses', async () => {
    const body = { email: 'owner@example.test', password };
    const first = await request('auth/register', body);
    const before = await prisma.user.findUniqueOrThrow({
      where: { email: body.email },
    });
    expect(
      (
        await request('auth/register', {
          ...body,
          password: 'different password value',
        })
      ).body,
    ).toEqual(first.body);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { email: body.email } }))
        .passwordHash,
    ).toBe(before.passwordHash);
    expect(
      (await request('auth/password-resets', { email: 'missing@example.test' }))
        .body,
    ).toEqual(
      (await request('auth/password-resets', { email: body.email })).body,
    );
    const missing = await request('auth/login', {
      email: 'missing@example.test',
      password,
    });
    expect(missing.status).toBe(401);
    expect(
      (
        await request('auth/login', {
          ...body,
          password: 'wrong password value',
        })
      ).body,
    ).toEqual(missing.body);
  });

  it('enforces session ownership, per-session and all-session revoke, and expiry', async () => {
    const owner = await verified();
    const other = await verified('other@example.test');
    expect(
      (
        await request(
          `sessions/${other.sessionId}`,
          undefined,
          owner.accessToken,
          'DELETE',
        )
      ).status,
    ).toBe(204);
    expect(
      (await request('sessions', undefined, other.accessToken, 'GET')).status,
    ).toBe(200);
    const second = (
      await request('auth/login', { email: 'owner@example.test', password })
    ).body;
    expect(
      (
        await request(
          `sessions/${owner.sessionId}`,
          undefined,
          second.accessToken,
          'DELETE',
        )
      ).status,
    ).toBe(204);
    expect(
      (await request('sessions', undefined, owner.accessToken, 'GET')).status,
    ).toBe(401);
    expect(
      (await request('sessions', undefined, second.accessToken, 'DELETE'))
        .status,
    ).toBe(204);
    expect(
      (await request('sessions', undefined, second.accessToken, 'GET')).status,
    ).toBe(401);
    await prisma.authSession.update({
      where: { id: other.sessionId },
      data: { expiresAt: new Date(0) },
    });
    expect(
      (await request('sessions', undefined, other.accessToken, 'GET')).status,
    ).toBe(401);
  });

  it('atomically consumes reset once, changes password, revokes sessions and invalidates other tokens', async () => {
    const login = await verified();
    await request('auth/password-resets', { email: 'owner@example.test' });
    const token = await emailToken('owner@example.test', 'reset_password');
    expect((await request('auth/verify-email', { token })).status).toBe(400);
    const newPassword = 'brand new secure password';
    const responses = await Promise.all(
      [1, 2].map(() =>
        request('auth/reset-password', { token, password: newPassword }),
      ),
    );
    expect(responses.map((r) => r.status).sort()).toEqual([204, 400]);
    expect(
      (await request('sessions', undefined, login.accessToken, 'GET')).status,
    ).toBe(401);
    expect(
      (await request('auth/login', { email: 'owner@example.test', password }))
        .status,
    ).toBe(401);
    expect(
      (
        await request('auth/login', {
          email: 'owner@example.test',
          password: newPassword,
        })
      ).status,
    ).toBe(200);
    expect(await prisma.authToken.count()).toBe(0);
    expect(
      await prisma.auditEvent.count({
        where: { action: 'auth.reset_password', outcome: 'success' },
      }),
    ).toBe(1);
  });

  it('rejects expired/replaced tokens; reset does not verify unverified accounts', async () => {
    const email = 'owner@example.test';
    await request('auth/register', { email, password });
    const old = await emailToken(email, 'verify_email');
    await request('auth/email-verifications', { email });
    expect((await request('auth/verify-email', { token: old })).status).toBe(
      400,
    );
    const current = await emailToken(email, 'verify_email');
    await prisma.authToken.updateMany({ data: { expiresAt: new Date(0) } });
    expect(
      (await request('auth/verify-email', { token: current })).status,
    ).toBe(400);
    await request('auth/password-resets', { email });
    expect(
      (
        await request('auth/reset-password', {
          token: await emailToken(email, 'reset_password'),
          password,
        })
      ).status,
    ).toBe(204);
    expect((await request('auth/login', { email, password })).status).toBe(200);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { email } }))
        .emailVerifiedAt,
    ).toBeNull();
    await request('auth/email-verifications', { email });
    expect(
      (
        await request('auth/verify-email', {
          token: await emailToken(email, 'verify_email'),
        })
      ).status,
    ).toBe(204);
  });

  it('prevents sessions from an old password after a concurrent reset', async () => {
    await verified();
    const user = await prisma.user.findUniqueOrThrow({
      where: { email: 'owner@example.test' },
    });
    await auth.requestEmail(user.email, 'reset_password');
    const token = await emailToken(user.email, 'reset_password');
    const newHash = await crypto.hashPassword('changed strong password');
    const hash = crypto.digest(crypto.token());
    await Promise.all([
      repository.createSession(
        user.id,
        user.passwordHash!,
        hash,
        new Date(Date.now() + 60_000),
      ),
      repository.consumeChallenge(
        crypto.digest(token),
        'reset_password',
        newHash,
      ),
    ]);
    expect(await repository.findSession(hash)).toBeNull();
    expect(
      await repository.createSession(
        user.id,
        user.passwordHash!,
        crypto.digest(crypto.token()),
        new Date(Date.now() + 60_000),
      ),
    ).toBeNull();
  });

  it('limits normalized email attempts, returns Retry-After and fails closed on storage errors', async () => {
    for (let i = 0; i < 5; i++)
      expect(
        (
          await request('auth/login', {
            email: ' Owner@Example.Test ',
            password,
          })
        ).status,
      ).toBe(401);
    const limited = await request('auth/login', {
      email: 'owner@example.test',
      password,
    });
    expect(limited.status).toBe(429);
    expect(Number(limited.headers.get('retry-after'))).toBeGreaterThan(0);
    expect(JSON.stringify(await prisma.authRateLimit.findMany())).not.toContain(
      'owner',
    );
    await prisma.authRateLimit.updateMany({ data: { expiresAt: new Date(0) } });
    expect(
      (await request('auth/login', { email: 'owner@example.test', password }))
        .status,
    ).toBe(401);
    const db = app.get<PrismaAuthRepository>(AUTH_REPOSITORY);
    const spy = jest
      .spyOn(db, 'takeRateLimit')
      .mockRejectedValueOnce(new Error('sensitive database detail'));
    expect(
      (await request('auth/login', { email: 'owner@example.test', password }))
        .body,
    ).toEqual({
      error: {
        code: 'AUTH_UNAVAILABLE',
        message: 'Authentication is temporarily unavailable',
      },
    });
    spy.mockRestore();
  });

  it('enforces atomic shared counters under concurrency and IP limit across emails', async () => {
    const secondRepository = new PrismaAuthRepository(prisma);
    const results = await Promise.all(
      Array.from({ length: 20 }, (_, i) =>
        (i % 2 ? repository : secondRepository).takeRateLimit(
          'a'.repeat(64),
          5,
          900,
        ),
      ),
    );
    expect(results.filter((n) => n === 0)).toHaveLength(5);
    for (let i = 0; i < 30; i++)
      expect(
        (
          await request('auth/password-resets', {
            email: `user${i}@example.test`,
          })
        ).status,
      ).toBe(202);
    expect(
      (await request('auth/password-resets', { email: 'new@example.test' }))
        .status,
    ).toBe(429);
  });

  it('retries mail failures without exposing token, and guards replacement from an old worker', async () => {
    await request('auth/register', { email: 'owner@example.test', password });
    sendMail.mockRejectedValueOnce(new Error('SMTP failed'));
    await worker.flush();
    expect(await prisma.authMailJob.count()).toBe(1);
    expect(await repository.claimMail()).toBeNull();
    await prisma.authMailJob.updateMany({ data: { availableAt: new Date(0) } });
    const old = await repository.claimMail();
    await auth.requestEmail('owner@example.test', 'verify_email');
    await repository.completeMail(old!.id);
    expect(await prisma.authMailJob.count()).toBe(1);
    await worker.flush();
    expect(await prisma.authMailJob.count()).toBe(0);
  });

  it('rolls back reset, login and revoke when audit storage fails', async () => {
    const login = await verified();
    const email = 'owner@example.test';
    await auth.requestEmail(email, 'reset_password');
    const token = await emailToken(email, 'reset_password');
    const before = await prisma.user.findUniqueOrThrow({ where: { email } });
    await prisma.$executeRaw`CREATE FUNCTION auth_test_reject_audit() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'Test audit outage'; END $$`;
    await prisma.$executeRaw`CREATE TRIGGER auth_test_audit_failure BEFORE INSERT ON "AuditEvent" FOR EACH ROW EXECUTE FUNCTION auth_test_reject_audit()`;
    try {
      expect(
        (
          await request('auth/reset-password', {
            token,
            password: 'changed test password',
          })
        ).status,
      ).toBe(503);
      expect(
        (await prisma.user.findUniqueOrThrow({ where: { email } }))
          .passwordHash,
      ).toBe(before.passwordHash);
      expect(
        (await request('sessions', undefined, login.accessToken, 'DELETE'))
          .status,
      ).toBe(503);
      expect(
        (await request('sessions', undefined, login.accessToken, 'GET')).status,
      ).toBe(200);
      expect((await request('auth/login', { email, password })).status).toBe(
        503,
      );
      expect(await prisma.authSession.count()).toBe(1);
    } finally {
      await prisma.$executeRaw`DROP TRIGGER auth_test_audit_failure ON "AuditEvent"`;
      await prisma.$executeRaw`DROP FUNCTION auth_test_reject_audit()`;
    }
    expect(
      (
        await request('auth/reset-password', {
          token,
          password: 'changed test password',
        })
      ).status,
    ).toBe(204);
  });

  it('handles concurrent registration and verification without duplicate identities or token reuse', async () => {
    const email = 'owner@example.test';
    const registrations = await Promise.all(
      [1, 2].map(() => request('auth/register', { email, password })),
    );
    expect(registrations.map((response) => response.status)).toEqual([
      202, 202,
    ]);
    expect(await prisma.user.count()).toBe(1);
    expect(await prisma.authMailJob.count()).toBe(1);
    const token = await emailToken(email, 'verify_email');
    const verification = await Promise.all(
      [1, 2].map(() => request('auth/verify-email', { token })),
    );
    expect(verification.map((response) => response.status).sort()).toEqual([
      204, 400,
    ]);
  });

  it('validates bodies and credentials without reflecting secrets', async () => {
    const response = await request('auth/register', {
      email: 'bad email',
      password: 'secret',
      role: 'staff',
    });
    expect(response.status).toBe(400);
    expect(response.body).toEqual({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request',
        details: [],
      },
    });
    expect(
      (
        await request('auth/register', {
          email: 'valid@example.test',
          password: 'a'.repeat(129),
        })
      ).status,
    ).toBe(400);
    expect(
      (await request('sessions', undefined, undefined, 'GET')).status,
    ).toBe(401);
    expect(
      (await request('sessions', undefined, 'staff-credential', 'GET')).status,
    ).toBe(401);
    const login = await verified();
    expect(
      (
        await request(
          'sessions/not-a-uuid',
          undefined,
          login.accessToken,
          'DELETE',
        )
      ).status,
    ).toBe(400);
  });
});
