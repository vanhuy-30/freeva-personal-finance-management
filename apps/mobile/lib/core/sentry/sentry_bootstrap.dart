import 'package:sentry_flutter/sentry_flutter.dart';

import 'sentry_scrub.dart';

/// Bật Sentry khi bản build có `SENTRY_DSN`. Không log DSN.
Future<void> runFreeva(Future<void> Function() boot) async {
  const dsn = String.fromEnvironment('SENTRY_DSN');
  if (dsn.isEmpty) {
    await boot();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'dev',
      );
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0;
      options.beforeSend = scrubSentryEvent;
      options.beforeBreadcrumb = scrubSentryBreadcrumb;
    },
    appRunner: () async {
      await boot();
      if (const bool.fromEnvironment('SENTRY_SMOKE')) {
        await Sentry.captureMessage('freeva.sentry.smoke');
      }
    },
  );
}
