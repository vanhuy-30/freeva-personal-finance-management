'use strict';

const dsn = process.env.SENTRY_DSN && process.env.SENTRY_DSN.trim();
if (!dsn || process.env.SENTRY_SMOKE !== '1') {
  console.log('sentry smoke skipped');
  process.exit(0);
}

async function main() {
  const Sentry = require('@sentry/nestjs');
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV || 'staging',
    includeLocalVariables: false,
    tracesSampleRate: 0,
    profileSessionSampleRate: 0,
    dataCollection: {
      userInfo: false,
      cookies: false,
      httpHeaders: false,
      httpBodies: [],
      urlQueryParams: false,
      databaseQueryData: false,
      queues: false,
      stackFrameVariables: false,
    },
  });
  Sentry.captureMessage('freeva.sentry.smoke', {
    level: 'info',
    tags: { smoke: '1' },
  });
  const flushed = await Sentry.flush(2000);
  if (!flushed) {
    console.log('sentry smoke flush timed out');
    process.exit(1);
  }
  console.log('sentry smoke sent');
}

main().catch(() => {
  console.log('sentry smoke failed');
  process.exit(1);
});
