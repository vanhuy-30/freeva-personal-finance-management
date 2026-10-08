import { Writable } from 'node:stream';
import pino from 'pino';
import { PINO_REDACT_CENSOR, pinoRedactOptions } from './pino-redact';

const EMAIL = 'user@example.com';
const SECRET = 'secret-token';
const PASSWORD = 'hunter2-secret';
const AMOUNT = 150000;
const ACCOUNT = '123456789012';
const IBAN = 'VN12FREE0000000001';

function captureLog(payload: object): string {
  const chunks: Buffer[] = [];
  const stream = new Writable({
    write(chunk: Buffer | string, _enc, cb) {
      chunks.push(typeof chunk === 'string' ? Buffer.from(chunk) : chunk);
      cb();
    },
  });
  const logger = pino({ redact: pinoRedactOptions, level: 'info' }, stream);
  logger.info(payload);
  return Buffer.concat(chunks).toString('utf8');
}

describe('pino redact (SEC-P0-003)', () => {
  it('redacts top-level PII, credentials, and money', () => {
    const out = captureLog({
      email: EMAIL,
      password: PASSWORD,
      RESEND_API_KEY: SECRET,
      SMTP_PASSWORD: PASSWORD,
      AUTH_SECRET_KEY: SECRET,
      pass: PASSWORD,
      apiKey: SECRET,
      passwordHash: PASSWORD,
      token: SECRET,
      idToken: SECRET,
      challengeToken: SECRET,
      nonce: SECRET,
      subject: SECRET,
      refreshToken: SECRET,
      accessToken: SECRET,
      amountMinor: AMOUNT,
      initialBalanceMinor: AMOUNT,
      creditLimitMinor: AMOUNT,
      balanceMinor: AMOUNT,
      accountNumber: ACCOUNT,
      iban: IBAN,
      userId: '11111111-1111-1111-1111-111111111111',
    });

    expect(out).toContain(PINO_REDACT_CENSOR);
    expect(out).toContain('11111111-1111-1111-1111-111111111111');
    expect(out).not.toContain(EMAIL);
    expect(out).not.toContain(PASSWORD);
    expect(out).not.toContain(SECRET);
    expect(out).not.toContain(String(AMOUNT));
    expect(out).not.toContain(ACCOUNT);
    expect(out).not.toContain(IBAN);
  });

  it('redacts one-level nested fields', () => {
    const out = captureLog({
      user: { email: EMAIL, password: PASSWORD },
      transaction: { amountMinor: AMOUNT, accountNumber: ACCOUNT },
      session: { token: SECRET, refreshToken: SECRET, accessToken: SECRET },
      account: {
        initialBalanceMinor: AMOUNT,
        creditLimitMinor: AMOUNT,
        balanceMinor: AMOUNT,
        iban: IBAN,
      },
    });

    expect(out).toContain(PINO_REDACT_CENSOR);
    expect(out).not.toContain(EMAIL);
    expect(out).not.toContain(PASSWORD);
    expect(out).not.toContain(SECRET);
    expect(out).not.toContain(String(AMOUNT));
    expect(out).not.toContain(ACCOUNT);
    expect(out).not.toContain(IBAN);
  });

  it('redacts two-level nested fields and HTTP headers', () => {
    const out = captureLog({
      req: {
        body: { email: EMAIL, password: PASSWORD },
        headers: {
          authorization: `Bearer ${SECRET}`,
          cookie: `sid=${SECRET}`,
          'set-cookie': `sid=${SECRET}`,
        },
      },
      res: {
        headers: {
          'set-cookie': `sid=${SECRET}`,
        },
      },
      wrapper: {
        transaction: { amountMinor: AMOUNT },
      },
    });

    expect(out).toContain(PINO_REDACT_CENSOR);
    expect(out).not.toContain(EMAIL);
    expect(out).not.toContain(PASSWORD);
    expect(out).not.toContain(SECRET);
    expect(out).not.toContain(String(AMOUNT));
  });
});
