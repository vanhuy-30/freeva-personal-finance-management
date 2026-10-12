import * as Sentry from "@sentry/nextjs";
import { scrubBreadcrumb, sentryBeforeSend } from "./sentry/scrub";

const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN?.trim() ?? "";

if (dsn) {
  Sentry.init({
    dsn,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 0,
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
