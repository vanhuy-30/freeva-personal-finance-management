import * as Sentry from "@sentry/nextjs";
import { scrubBreadcrumb, sentryBeforeSend } from "./scrub";

const dsn = process.env.SENTRY_DSN?.trim() ?? "";

if (dsn && process.env.NODE_ENV !== "test") {
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV,
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
    beforeSend(event, hint) {
      return sentryBeforeSend(event, hint);
    },
    beforeBreadcrumb(breadcrumb) {
      return scrubBreadcrumb(breadcrumb);
    },
  });
}
