import { FeedbackModule } from '../src/modules/feedback/feedback.module';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { Writable } from 'node:stream';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { LoggerModule } from 'nestjs-pino';
import { PrismaModule } from '../src/infrastructure/prisma/prisma.module';
import { PrismaService } from '../src/infrastructure/prisma/prisma.service';
import { AuthMailWorker } from '../src/modules/auth/infrastructure/auth-mail.worker';
import { httpRequestSerializer } from '../src/core/logging/http-request.serializer';
import { pinoRedactOptions } from '../src/core/logging/pino-redact';

const databaseUrl = process.env.AUTH_TEST_DATABASE_URL;
if (!databaseUrl || new URL(databaseUrl).pathname !== '/auth_test') {
  throw new Error('AUTH_TEST_DATABASE_URL must point to an isolated database named auth_test');
}
process.env.DATABASE_URL = databaseUrl;

describe('DS-P2-003 feedback HTTP + PostgreSQL', () => {
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
        PrismaModule, FeedbackModule,
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
    await prisma.user.create({ data: { id, email: `${id}@example.test`, defaultCurrencyCode: 'VND' } });
    const bearer = randomBytes(32).toString('hex');
    await prisma.authSession.create({ data: { userId: id, tokenHash: createHash('sha256').update(bearer).digest('hex'), expiresAt: new Date(Date.now() + 60000) } });
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
      await prisma.feedback.deleteMany({ where: { userId: { in: fixtureUsers } } });
      await prisma.user.deleteMany({ where: { id: { in: fixtureUsers } } });
    }
    await app?.close();
  });
  const send = (body: object, bearer = token) =>
    fetch(`${base}/api/v1/feedback`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(bearer ? { Authorization: `Bearer ${bearer}` } : {}) },
      body: JSON.stringify(body),
    });
  const valid = { kind: 'idea', topic: 'record', message: '  Nhắc ghi chi buổi tối  ', allowReply: true, appVersion: '0.0.1+1' };

  it('stores a trimmed message for the owner and keeps it out of the logs', async () => {
    const res = await send(valid);
    expect(res.status).toBe(204);
    expect(res.headers.get('cache-control')).toBe('no-store');
    expect(await prisma.feedback.findMany({ where: { userId: owner } })).toMatchObject([
      { kind: 'idea', topic: 'record', message: 'Nhắc ghi chi buổi tối', allowReply: true },
    ]);
    expect(logs).not.toContain('Nhắc ghi chi');
  });

  it('rejects bad input and anonymous callers', async () => {
    for (const bad of [{ ...valid, kind: 'rant' }, { ...valid, topic: 'x' }, { ...valid, message: '   ' }, { ...valid, message: 'x'.repeat(2001) }, { ...valid, allowReply: 'yes' }, { ...valid, userId: owner }]) {
      expect((await send(bad)).status).toBe(400);
    }
    expect((await send(valid, '')).status).toBe(401);
    expect(await prisma.feedback.count({ where: { userId: owner } })).toBe(0);
  });

  it('allows five an hour', async () => {
    for (let i = 0; i < 5; i++) expect((await send(valid)).status).toBe(204);
    const sixth = await send(valid);
    expect(sixth.status).toBe(429);
    expect(sixth.headers.get('retry-after')).toBe('3600');
  });
});
