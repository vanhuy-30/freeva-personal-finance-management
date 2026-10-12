import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { configureHttp } from '../src/core/http/configure-http';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AdminUserLookupModule } from '../src/modules/admin-user-lookup/admin-user-lookup.module';
import { AuthModule } from '../src/modules/auth/auth.module';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { HealthModule } from '../src/modules/health/health.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error(
    'AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test',
  );
}
process.env.DATABASE_URL = databaseUrl;

const staffToken = 's'.repeat(40);
const staffActorId = '00000000-0000-4000-8000-000000000001';
const allowedOrigin = 'http://localhost:3001';

describe('SEC-P1-001 HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  const previousCors = process.env.CORS_ORIGINS;

  beforeAll(async () => {
    process.env.CORS_ORIGINS = allowedOrigin;
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
              SMTP_PORT: '1025',
              MAIL_FROM: 'noreply@example.test',
              STAFF_AUTH_TOKEN: staffToken,
              STAFF_ACTOR_ID: staffActorId,
            }),
          ],
        }),
        PrismaModule,
        HealthModule,
        AuthModule,
        AdminUserLookupModule,
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

  afterAll(async () => {
    if (previousCors === undefined) delete process.env.CORS_ORIGINS;
    else process.env.CORS_ORIGINS = previousCors;
    if (prisma) await prisma.authRateLimit.deleteMany();
    await app?.close();
  });

  it('sends Helmet headers and reflects only the CORS allowlist', async () => {
    const health = await fetch(`${base}/api/health`);
    expect(health.status).toBe(200);
    expect(health.headers.get('x-content-type-options')).toBe('nosniff');
    expect(health.headers.get('x-frame-options')).toBe('SAMEORIGIN');

    const allowed = await fetch(`${base}/api/health`, {
      headers: { Origin: allowedOrigin },
    });
    expect(allowed.headers.get('access-control-allow-origin')).toBe(
      allowedOrigin,
    );
    expect(allowed.headers.get('access-control-allow-credentials')).toBe(
      'true',
    );

    const denied = await fetch(`${base}/api/health`, {
      headers: { Origin: 'http://evil.example' },
    });
    expect(denied.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('rate limits malformed auth bodies by IP and does not store the raw email', async () => {
    const longEmail = `${'a'.repeat(1025)}@example.test`;
    for (const body of [{ email: 1 }, { email: longEmail }]) {
      await prisma.authRateLimit.deleteMany();
      for (let attempt = 0; attempt < 30; attempt += 1) {
        expect((await postEmailStep(body)).status).toBe(400);
      }
      const limited = await postEmailStep(body);
      expect(limited.status).toBe(429);
      expect(Number(limited.headers.get('retry-after'))).toBeGreaterThan(0);
      const payload = await limited.text();
      expect(payload).not.toContain(longEmail);
      expect(payload).not.toContain('@');
      expect(
        JSON.stringify(await prisma.authRateLimit.findMany()),
      ).not.toContain(longEmail);
    }
  });

  it('rejects a user session on staff lookup and a staff token on user sessions', async () => {
    const userId = randomUUID();
    const email = `${userId}@example.test`;
    const bearer = randomBytes(32).toString('hex');
    await prisma.user.create({
      data: { id: userId, email, defaultCurrencyCode: 'VND' },
    });
    await prisma.authSession.create({
      data: {
        userId,
        tokenHash: createHash('sha256').update(bearer).digest('hex'),
        expiresAt: new Date(Date.now() + 60_000),
      },
    });

    try {
      const lookup = await fetch(`${base}/api/admin/user-lookups`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bearer}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });
      expect(lookup.status).toBe(401);
      expect(await lookup.text()).not.toContain(email);

      const sessions = await fetch(`${base}/api/v1/sessions`, {
        headers: { Authorization: `Bearer ${staffToken}` },
      });
      expect(sessions.status).toBe(401);
    } finally {
      await prisma.authSession.deleteMany({ where: { userId } });
      await prisma.user.delete({ where: { id: userId } });
    }
  });

  function postEmailStep(body: unknown): Promise<Response> {
    return fetch(`${base}/api/v1/auth/email-step`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    });
  }
});
