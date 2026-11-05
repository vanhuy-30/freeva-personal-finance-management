import { HttpException } from '@nestjs/common';
import type { Breadcrumb, ErrorEvent, EventHint } from '@sentry/nestjs';

/** Same censor as Pino. Checklist: docs/architecture/pii-log-checklist.md */
export const SENTRY_REDACT_CENSOR = '[REDACTED]';

const SENSITIVE_KEYS = new Set([
  'email',
  'password',
  'pass',
  'apikey',
  'resend_api_key',
  'smtp_password',
  'auth_secret_key',
  'passwordhash',
  'token',
  'idtoken',
  'challengetoken',
  'nonce',
  'subject',
  'tokenhash',
  'encryptedtoken',
  'refreshtoken',
  'fcmtoken',
  'private_key',
  'accesstoken',
  'authorization',
  'cookie',
  'set-cookie',
  'accountnumber',
  'iban',
  'database_url',
  'sentry_dsn',
  'amountminor',
  'initialbalanceminor',
  'creditlimitminor',
  'balanceminor',
  'incomeminor',
  'expenseminor',
  'netminor',
  'transferminor',
  'assetsminor',
  'liabilitiesminor',
  'networthminor',
]);

const EMAIL_RE = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const BEARER_RE = /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi;
const SENTRY_DSN_RE = /https:\/\/[^\s@]+@[^\s]*sentry\.io[^\s]*/gi;

export function scrubString(value: string): string {
  return value
    .replace(EMAIL_RE, SENTRY_REDACT_CENSOR)
    .replace(BEARER_RE, `Bearer ${SENTRY_REDACT_CENSOR}`)
    .replace(SENTRY_DSN_RE, SENTRY_REDACT_CENSOR);
}

export function isSensitiveKey(key: string): boolean {
  const normalized = key.toLowerCase();
  return SENSITIVE_KEYS.has(normalized) || normalized.endsWith('minor');
}

export function stripUrl(url: string): string {
  const query = url.indexOf('?');
  const hash = url.indexOf('#');
  let end = url.length;
  if (query >= 0) {
    end = Math.min(end, query);
  }
  if (hash >= 0) {
    end = Math.min(end, hash);
  }
  return url.slice(0, end);
}

function redactValue(value: unknown, seen: WeakSet<object>): unknown {
  if (typeof value === 'string') {
    return scrubString(value);
  }
  if (value === null || typeof value !== 'object') {
    return value;
  }
  if (seen.has(value)) {
    return SENTRY_REDACT_CENSOR;
  }
  seen.add(value);
  if (Array.isArray(value)) {
    return value.map((item) => redactValue(item, seen));
  }
  const next: Record<string, unknown> = {};
  for (const [key, child] of Object.entries(value as Record<string, unknown>)) {
    next[key] = isSensitiveKey(key)
      ? SENTRY_REDACT_CENSOR
      : redactValue(child, seen);
  }
  return next;
}

function isHttpBreadcrumb(breadcrumb: Breadcrumb): boolean {
  return breadcrumb.type === 'http' || breadcrumb.category === 'http';
}

export function scrubBreadcrumb(breadcrumb: Breadcrumb): Breadcrumb {
  const next: Breadcrumb = {
    ...breadcrumb,
    message: breadcrumb.message ? scrubString(breadcrumb.message) : breadcrumb.message,
  };
  if (!breadcrumb.data) {
    return next;
  }
  if (isHttpBreadcrumb(breadcrumb)) {
    const data = breadcrumb.data;
    const url = typeof data.url === 'string' ? stripUrl(data.url) : undefined;
    next.data = {
      method: data.method,
      status_code: data.status_code,
      url,
    };
    return next;
  }
  next.data = redactValue(breadcrumb.data, new WeakSet()) as Breadcrumb['data'];
  return next;
}

function responseStatus(event: ErrorEvent): number | undefined {
  const response = event.contexts?.response;
  if (!response || typeof response !== 'object' || !('status_code' in response)) {
    return undefined;
  }
  const status = response.status_code;
  return typeof status === 'number' ? status : undefined;
}

export function scrubSentryEvent(event: ErrorEvent): ErrorEvent {
  const scrubbed: ErrorEvent = { ...event, user: undefined };
  if (scrubbed.request) {
    scrubbed.request = {
      method: scrubbed.request.method,
      url: scrubbed.request.url ? stripUrl(scrubbed.request.url) : undefined,
    };
  }
  if (scrubbed.message) {
    scrubbed.message = scrubString(scrubbed.message);
  }
  if (scrubbed.logentry?.message) {
    scrubbed.logentry = {
      ...scrubbed.logentry,
      message: scrubString(scrubbed.logentry.message),
    };
  }
  if (scrubbed.exception?.values) {
    scrubbed.exception = {
      values: scrubbed.exception.values.map((item) => {
        const frames = item.stacktrace?.frames?.map((frame) => {
          if (!frame.vars) {
            return frame;
          }
          const { vars: _vars, ...rest } = frame;
          return rest;
        });
        return {
          ...item,
          value: item.value ? scrubString(item.value) : item.value,
          stacktrace: item.stacktrace
            ? { ...item.stacktrace, frames }
            : item.stacktrace,
        };
      }),
    };
  }
  if (scrubbed.extra) {
    scrubbed.extra = redactValue(scrubbed.extra, new WeakSet()) as ErrorEvent['extra'];
  }
  if (scrubbed.contexts) {
    scrubbed.contexts = redactValue(
      scrubbed.contexts,
      new WeakSet(),
    ) as ErrorEvent['contexts'];
  }
  if (scrubbed.tags) {
    scrubbed.tags = redactValue(scrubbed.tags, new WeakSet()) as ErrorEvent['tags'];
  }
  if (scrubbed.breadcrumbs) {
    scrubbed.breadcrumbs = scrubbed.breadcrumbs.map(scrubBreadcrumb);
  }
  return scrubbed;
}

export function sentryBeforeSend(
  event: ErrorEvent,
  hint: EventHint,
): ErrorEvent | null {
  const status = responseStatus(event);
  if (status !== undefined && status < 500) {
    return null;
  }
  if (
    hint.originalException instanceof HttpException &&
    hint.originalException.getStatus() < 500
  ) {
    return null;
  }
  return scrubSentryEvent(event);
}
