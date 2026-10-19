import * as Sentry from '@sentry/nestjs';
import { scrubBreadcrumb, sentryBeforeSend } from './core/sentry/scrub';

const dsn = process.env.SENTRY_DSN?.trim() ?? '';

export const sentryEnabled =
  dsn.length > 0 && process.env.NODE_ENV !== 'test';

if (sentryEnabled) {
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV ?? 'development',
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
    beforeSend: sentryBeforeSend,
    beforeBreadcrumb(breadcrumb) {
      return scrubBreadcrumb(breadcrumb);
    },
  });
}
