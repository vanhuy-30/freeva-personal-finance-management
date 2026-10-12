/** Crash event scrubber for web admin. Key list matches the API scrubber (INF-P1-001). */

export const SENTRY_REDACT_CENSOR = "[REDACTED]";

const SENSITIVE_KEYS = new Set([
  "email",
  "password",
  "pass",
  "apikey",
  "resend_api_key",
  "smtp_password",
  "auth_secret_key",
  "passwordhash",
  "token",
  "idtoken",
  "challengetoken",
  "nonce",
  "subject",
  "tokenhash",
  "encryptedtoken",
  "refreshtoken",
  "accesstoken",
  "authorization",
  "cookie",
  "set-cookie",
  "accountnumber",
  "iban",
  "database_url",
  "sentry_dsn",
  "amountminor",
  "initialbalanceminor",
  "creditlimitminor",
  "balanceminor",
  "incomeminor",
  "expenseminor",
  "netminor",
  "transferminor",
  "assetsminor",
  "liabilitiesminor",
  "networthminor",
]);

const EMAIL_RE = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
const BEARER_RE = /Bearer\s+[A-Za-z0-9\-._~+/]+=*/gi;
const SENTRY_DSN_RE = /https:\/\/[^\s@]+@[^\s]*sentry\.io[^\s]*/gi;

export interface ScrubbableBreadcrumb {
  type?: string;
  category?: string;
  message?: string;
  data?: Record<string, unknown>;
}

export interface ScrubbableEvent {
  message?: string;
  user?: unknown;
  request?: {
    method?: string;
    url?: string;
    data?: unknown;
    cookies?: unknown;
    headers?: unknown;
    query_string?: unknown;
    env?: unknown;
  };
  extra?: Record<string, unknown>;
  contexts?: Record<string, unknown>;
  tags?: Record<string, unknown>;
  breadcrumbs?: ScrubbableBreadcrumb[];
  exception?: {
    values?: Array<{
      type?: string;
      value?: string;
      stacktrace?: { frames?: Array<Record<string, unknown>> };
    }>;
  };
  logentry?: { message?: string; params?: unknown[] };
}

export function scrubString(value: string): string {
  return value
    .replace(EMAIL_RE, SENTRY_REDACT_CENSOR)
    .replace(BEARER_RE, `Bearer ${SENTRY_REDACT_CENSOR}`)
    .replace(SENTRY_DSN_RE, SENTRY_REDACT_CENSOR);
}

export function isSensitiveKey(key: string): boolean {
  const normalized = key.toLowerCase();
  return SENSITIVE_KEYS.has(normalized) || normalized.endsWith("minor");
}

export function stripUrl(url: string): string {
  const query = url.indexOf("?");
  const hash = url.indexOf("#");
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
  if (typeof value === "string") {
    return scrubString(value);
  }
  if (value === null || typeof value !== "object") {
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

function isHttpBreadcrumb(breadcrumb: ScrubbableBreadcrumb): boolean {
  return breadcrumb.type === "http" || breadcrumb.category === "http";
}

export function scrubBreadcrumb<T>(breadcrumb: T): T {
  const source = breadcrumb as ScrubbableBreadcrumb;
  const next = {
    ...source,
    message: source.message ? scrubString(source.message) : source.message,
  };
  if (!source.data) {
    return next as T;
  }
  if (isHttpBreadcrumb(source)) {
    const data = source.data;
    const url = typeof data.url === "string" ? stripUrl(data.url) : undefined;
    next.data = {
      method: data.method,
      status_code: data.status_code,
      url,
    };
    return next as T;
  }
  next.data = redactValue(source.data, new WeakSet()) as ScrubbableBreadcrumb["data"];
  return next as T;
}

function responseStatus(event: ScrubbableEvent): number | undefined {
  const response = event.contexts?.response;
  if (!response || typeof response !== "object" || !("status_code" in response)) {
    return undefined;
  }
  const status = response.status_code;
  return typeof status === "number" ? status : undefined;
}

function clientStatus(error: unknown): number | undefined {
  if (!error || typeof error !== "object") {
    return undefined;
  }
  const record = error as { status?: unknown; statusCode?: unknown };
  if (typeof record.status === "number") {
    return record.status;
  }
  if (typeof record.statusCode === "number") {
    return record.statusCode;
  }
  return undefined;
}

export function scrubSentryEvent<T>(event: T): T {
  const source = event as ScrubbableEvent;
  const scrubbed: ScrubbableEvent = { ...source, user: undefined };
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
          if (!("vars" in frame)) {
            return frame;
          }
          const rest = { ...frame };
          delete rest.vars;
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
    scrubbed.extra = redactValue(scrubbed.extra, new WeakSet()) as ScrubbableEvent["extra"];
  }
  if (scrubbed.contexts) {
    scrubbed.contexts = redactValue(
      scrubbed.contexts,
      new WeakSet(),
    ) as ScrubbableEvent["contexts"];
  }
  if (scrubbed.tags) {
    scrubbed.tags = redactValue(scrubbed.tags, new WeakSet()) as ScrubbableEvent["tags"];
  }
  if (scrubbed.breadcrumbs) {
    scrubbed.breadcrumbs = scrubbed.breadcrumbs.map((breadcrumb) =>
      scrubBreadcrumb(breadcrumb),
    );
  }
  return scrubbed as T;
}

export function sentryBeforeSend<T>(
  event: T,
  hint?: { originalException?: unknown },
): T | null {
  const scrubbable = event as ScrubbableEvent;
  const status = responseStatus(scrubbable);
  if (status !== undefined && status < 500) {
    return null;
  }
  const exceptionStatus = clientStatus(hint?.originalException);
  if (exceptionStatus !== undefined && exceptionStatus < 500) {
    return null;
  }
  return scrubSentryEvent(event);
}
