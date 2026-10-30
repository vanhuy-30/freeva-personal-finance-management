import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { PushModule } from '../src/modules/push/push.module';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('BE-P2-015 push tokens HTTP + PostgreSQL', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let base: string;
  const users: string[] = [];

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({ ignoreEnvFile: true, isGlobal: true, load: [() => ({
          AUTH_SECRET_KEY: randomBytes(32).toString('hex'), NODE_ENV: 'test', MAIL_PROVIDER: 'smtp',
          SMTP_HOST: 'localhost', SMTP_PORT: '1025', MAIL_FROM: 'noreply@example.test',
        })] }),
        PrismaModule, PushModule,
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
    if (prisma) await prisma.user.deleteMany({ where: { id: { in: users } } });
    await app?.close();
  });

  async function login() {
    const id = randomUUID();
    users.push(id);
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    const session = await prisma.authSession.create({
      data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60_000) },
    });
    return { id, bearer, sessionId: session.id };
  }

  const call = (method: string, bearer: string | null, body?: unknown) => fetch(`${base}/api/v1/push-tokens`, {
    method,
    headers: { 'content-type': 'application/json', ...(bearer ? { authorization: `Bearer ${bearer}` } : {}) },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  it('requires a session and validates the body', async () => {
    expect((await call('PUT', null, { token: 'x'.repeat(30), platform: 'ios' })).status).toBe(401);
    const a = await login();
    expect((await call('PUT', a.bearer, { token: 'short', platform: 'ios' })).status).toBe(400);
    expect((await call('PUT', a.bearer, { token: 'x'.repeat(30), platform: 'web' })).status).toBe(400);
  });

  it('binds one token per session, replaces it, and moves a token to the new session', async () => {
    const a = await login();
    const b = await login();
    const t1 = `t1-${randomUUID()}-${randomUUID()}`;
    const t2 = `t2-${randomUUID()}-${randomUUID()}`;
    expect((await call('PUT', a.bearer, { token: t1, platform: 'android' })).status).toBe(204);
    expect((await call('PUT', a.bearer, { token: t2, platform: 'android' })).status).toBe(204);
    expect(await prisma.pushToken.findMany({ where: { userId: a.id } })).toHaveLength(1);
    expect((await call('PUT', b.bearer, { token: t2, platform: 'ios' })).status).toBe(204);
    expect(await prisma.pushToken.count({ where: { userId: a.id } })).toBe(0);
    expect(await prisma.pushToken.findUnique({ where: { token: t2 } })).toMatchObject({ userId: b.id, platform: 'ios' });
  });

  it('DELETE removes the token and ending the session cascades', async () => {
    const a = await login();
    await call('PUT', a.bearer, { token: `t3-${randomUUID()}-${randomUUID()}`, platform: 'ios' });
    expect((await call('DELETE', a.bearer)).status).toBe(204);
    expect((await call('DELETE', a.bearer)).status).toBe(204);
    expect(await prisma.pushToken.count({ where: { userId: a.id } })).toBe(0);

    const b = await login();
    await call('PUT', b.bearer, { token: `t4-${randomUUID()}-${randomUUID()}`, platform: 'ios' });
    await prisma.authSession.delete({ where: { id: b.sessionId } });
    expect(await prisma.pushToken.count({ where: { userId: b.id } })).toBe(0);
  });
});
