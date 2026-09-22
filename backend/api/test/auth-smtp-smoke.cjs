// Local disposable PostgreSQL + Mailhog only; run after `pnpm --filter @freeva/api build`.
const assert = require('node:assert/strict');
const { randomBytes } = require('node:crypto');
const database = new URL(
  process.env.AUTH_TEST_DATABASE_URL ?? 'http://invalid',
);
assert.equal(database.hostname, '127.0.0.1');
assert.equal(database.pathname, '/auth_test');
Object.assign(process.env, {
  DATABASE_URL: database.toString(),
  NODE_ENV: 'test',
  AUTH_SECRET_KEY: randomBytes(32).toString('hex'),
  SMTP_HOST: '127.0.0.1',
  SMTP_PORT: '51025',
  SMTP_FROM: 'Freeva <noreply@example.test>',
  SMTP_USER: '',
  SMTP_PASSWORD: '',
  LOG_LEVEL: 'silent',
});
const { NestFactory } = require('@nestjs/core');
const { ValidationPipe } = require('@nestjs/common');
const { AppModule } = require('../dist/app.module');
const {
  AuthMailWorker,
} = require('../dist/modules/auth/infrastructure/auth-mail.worker');

let stage = 'bootstrap';
async function main() {
  const app = await NestFactory.create(AppModule, { logger: false });
  app.setGlobalPrefix('api');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  await app.listen(0, '127.0.0.1');
  try {
    const base = await app.getUrl();
    const email = `smtp-${randomBytes(6).toString('hex')}@example.test`;
    const password = 'local test password only';
    async function post(path, body, expected) {
      stage = path;
      const response = await fetch(`${base}/api/v1/auth/${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      assert.equal(response.status, expected);
      return response.status === 204 ? null : response.json();
    }
    async function deliveredToken() {
      stage = 'smtp-delivery';
      await app.get(AuthMailWorker).flush();
      const response = await fetch('http://127.0.0.1:58025/api/v2/messages');
      assert.equal(response.status, 200);
      const mail = (await response.json()).items.find((item) =>
        item.Content.Headers.To.some((to) => to.includes(email)),
      );
      assert.ok(mail, 'SMTP message delivered to local Mailhog');
      const encoding = mail.Content.Headers['Content-Transfer-Encoding']?.[0];
      const body =
        encoding === 'base64'
          ? Buffer.from(mail.Content.Body, 'base64').toString('utf8')
          : mail.Content.Body.replace(/=\r?\n/g, '').replace(
              /=([a-f0-9]{2})/gi,
              (_, hex) => String.fromCharCode(parseInt(hex, 16)),
            );
      const token = body.match(/\b[a-f0-9]{64}\b/)?.[0];
      assert.ok(token, 'Single-use token delivered in message body');
      return token;
    }
    await post('register', { email, password }, 202);
    await post('verify-email', { token: await deliveredToken() }, 204);
    const login = await post('login', { email, password }, 200);
    assert.equal(login.tokenType, 'Bearer');
    await post('password-resets', { email }, 202);
    await post(
      'reset-password',
      {
        token: await deliveredToken(),
        password: 'changed local test password',
      },
      204,
    );
    const oldSession = await fetch(`${base}/api/v1/sessions`, {
      headers: { Authorization: `Bearer ${login.accessToken}` },
    });
    assert.equal(oldSession.status, 401);
    await post(
      'login',
      { email, password: 'changed local test password' },
      200,
    );
    console.log(
      'PASS: real SMTP verification/reset delivery, login and session revocation',
    );
  } finally {
    await app.close();
  }
}
main().catch((error) => {
  console.error('SMTP smoke failed', {
    stage,
    name: error.name,
    code: error.code,
    actual: typeof error.actual === 'number' ? error.actual : undefined,
    expected: typeof error.expected === 'number' ? error.expected : undefined,
  });
  process.exitCode = 1;
});
