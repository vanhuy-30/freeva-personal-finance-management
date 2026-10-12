const dsn = process.env.SENTRY_DSN && process.env.SENTRY_DSN.trim();
if (!dsn || process.env.SENTRY_SMOKE !== "1") {
  console.log("sentry smoke skipped");
  process.exit(0);
}

const Sentry = await import("@sentry/nextjs");
Sentry.init({
  dsn,
  environment: process.env.NODE_ENV || "staging",
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
});
Sentry.captureMessage("freeva.sentry.smoke", {
  level: "info",
  tags: { smoke: "1" },
});
const flushed = await Sentry.flush(2000);
if (!flushed) {
  console.log("sentry smoke flush timed out");
  process.exit(1);
}
console.log("sentry smoke sent");
