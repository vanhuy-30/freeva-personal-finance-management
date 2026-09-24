/** Paths Pino che trong JSON log. Checklist: docs/architecture/pii-log-checklist.md */

const nested = (key: string): string[] => [key, `*.${key}`, `*.*.${key}`];

export const PINO_REDACT_CENSOR = '[REDACTED]';

export const PINO_REDACT_PATHS: string[] = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["set-cookie"]',
  'res.headers["set-cookie"]',
  ...nested('password'),
  ...nested('pass'),
  ...nested('apiKey'),
  ...nested('RESEND_API_KEY'),
  ...nested('SMTP_PASSWORD'),
  ...nested('AUTH_SECRET_KEY'),
  ...nested('passwordHash'),
  ...nested('token'),
  ...nested('idToken'),
  ...nested('challengeToken'),
  ...nested('nonce'),
  ...nested('subject'),
  ...nested('tokenHash'),
  ...nested('encryptedToken'),
  ...nested('refreshToken'),
  ...nested('accessToken'),
  ...nested('email'),
  ...nested('amountMinor'),
  ...nested('initialBalanceMinor'),
  ...nested('creditLimitMinor'),
  ...nested('balanceMinor'),
  ...nested('accountNumber'),
  ...nested('iban'),
];

export const pinoRedactOptions = {
  paths: PINO_REDACT_PATHS,
  censor: PINO_REDACT_CENSOR,
};
