import {
  BadRequestException,
  HttpException,
  ServiceUnavailableException,
} from '@nestjs/common';
import type { Breadcrumb, ErrorEvent, EventHint } from '@sentry/nestjs';
import { shouldCaptureException } from './capture-policy';
import {
  SENTRY_REDACT_CENSOR,
  scrubBreadcrumb,
  scrubSentryEvent,
  sentryBeforeSend,
} from './scrub';

const EMAIL = 'user@example.com';
const SECRET = 'secret-token';
const PASSWORD = 'hunter2-secret';
const AMOUNT = 150000;
const ACCOUNT = '123456789012';
const IBAN = 'VN12FREE0000000001';
const USER_ID = '11111111-1111-4111-8111-111111111111';

function event(partial: Omit<ErrorEvent, 'type'>): ErrorEvent {
  return { type: undefined, ...partial };
}

describe('sentry scrub (INF-P1-001)', () => {
  it('redacts PII, credentials, money, and secrets', () => {
    const scrubbed = scrubSentryEvent(
      event({
        message: `login failed for ${EMAIL} Bearer ${SECRET}`,
        user: { email: EMAIL, id: USER_ID, ip_address: '203.0.113.5' },
        request: {
          method: 'POST',
          url: `https://api.example.com/api/v1/auth/login?token=${SECRET}`,
          data: { email: EMAIL, password: PASSWORD, amountMinor: AMOUNT },
          cookies: { session: SECRET },
          headers: { authorization: `Bearer ${SECRET}` },
          query_string: `token=${SECRET}`,
          env: { DATABASE_URL: 'postgres://user:pass@db/freeva' },
        },
        extra: {
          email: EMAIL,
          password: PASSWORD,
          token: SECRET,
          amountMinor: AMOUNT,
          openingBalanceMinor: AMOUNT,
          accountNumber: ACCOUNT,
          iban: IBAN,
          DATABASE_URL: 'postgres://user:pass@db/freeva',
          userId: USER_ID,
          note: `reach ${EMAIL}`,
        },
        tags: { email: EMAIL, smoke: '1' },
        exception: {
          values: [
            {
              type: 'Error',
              value: `smtp failed for ${EMAIL}`,
              stacktrace: {
                frames: [{ filename: 'auth.ts', vars: { token: SECRET } }],
              },
            },
          ],
        },
        breadcrumbs: [
          {
            type: 'http',
            category: 'http',
            message: EMAIL,
            data: {
              method: 'POST',
              url: `https://api.example.com/sync?email=${EMAIL}`,
              status_code: 500,
              request_body_size: 42,
              'url.query': `email=${EMAIL}`,
            },
          },
        ],
      }),
    );

    const serialized = JSON.stringify(scrubbed);
    expect(serialized).toContain(SENTRY_REDACT_CENSOR);
    expect(serialized).toContain(USER_ID);
    expect(serialized).toContain('POST');
    expect(serialized).toContain('https://api.example.com/api/v1/auth/login');
    expect(serialized).not.toContain(EMAIL);
    expect(serialized).not.toContain(PASSWORD);
    expect(serialized).not.toContain(SECRET);
    expect(serialized).not.toContain(String(AMOUNT));
    expect(serialized).not.toContain(ACCOUNT);
    expect(serialized).not.toContain(IBAN);
    expect(serialized).not.toContain('postgres://');
    expect(serialized).not.toContain('203.0.113.5');
    expect(serialized).not.toContain('query_string');
    expect(scrubbed.user).toBeUndefined();
    expect(scrubbed.request).toEqual({
      method: 'POST',
      url: 'https://api.example.com/api/v1/auth/login',
    });
    expect(scrubbed.exception?.values?.[0]?.stacktrace?.frames?.[0]).toEqual({
      filename: 'auth.ts',
    });
    expect(scrubbed.breadcrumbs?.[0]?.data).toEqual({
      method: 'POST',
      status_code: 500,
      url: 'https://api.example.com/sync',
    });
    expect(scrubbed.tags).toEqual({ email: SENTRY_REDACT_CENSOR, smoke: '1' });
    expect(scrubbed.extra).toMatchObject({ userId: USER_ID });
  });

  it('strips query and fragment from breadcrumb urls', () => {
    const breadcrumb: Breadcrumb = {
      category: 'http',
      data: { url: '/api/health?token=abc#frag', method: 'GET', status_code: 200 },
    };
    expect(scrubBreadcrumb(breadcrumb).data?.url).toBe('/api/health');
  });

  it('drops client HTTP errors and keeps server failures', () => {
    const hint = (exception: unknown): EventHint => ({ originalException: exception });
    const client = event({ message: 'bad request' });
    expect(
      sentryBeforeSend(client, hint(new BadRequestException('invalid'))),
    ).toBeNull();
    expect(
      sentryBeforeSend(
        event({
          message: 'missing',
          contexts: { response: { status_code: 404 } },
        }),
        {},
      ),
    ).toBeNull();

    const server = sentryBeforeSend(
      event({ message: `down ${EMAIL}` }),
      hint(new ServiceUnavailableException('down')),
    );
    expect(server?.message).toBe(`down ${SENTRY_REDACT_CENSOR}`);

    const unknown = sentryBeforeSend(
      event({ message: 'boom' }),
      hint(new Error('boom')),
    );
    expect(unknown?.message).toBe('boom');
  });

  it('keeps HTTP 500 exceptions for capture policy', () => {
    expect(shouldCaptureException(new BadRequestException('invalid'))).toBe(false);
    expect(shouldCaptureException(new HttpException('down', 500))).toBe(true);
    expect(shouldCaptureException(new Error('boom'))).toBe(true);
  });
});
