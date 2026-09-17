import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/debug_analytics_service.dart';
import 'package:mobile/core/logging/app_logger.dart';

void main() {
  group('DebugAnalyticsService', () {
    late _RecordingLogger logger;
    late DebugAnalyticsService service;

    setUp(() {
      logger = _RecordingLogger();
      service = DebugAnalyticsService(logger);
    });

    test('logs a versioned catalog event at debug level', () {
      service.track(AnalyticsEvent.onboardingStarted);

      expect(logger.debugMessages, hasLength(1));
      expect(
        _payloadFrom(logger.debugMessages.single),
        <String, Object>{
          'event': 'onboarding_started',
          'schema_version': 1,
        },
      );
    });

    test('logs only the approved transaction type property', () {
      service.track(
        AnalyticsEvent.transactionCreated(TransactionAnalyticsType.expense),
      );

      expect(
        _payloadFrom(logger.debugMessages.single),
        <String, Object>{
          'event': 'transaction_created',
          'schema_version': 1,
          'type': 'expense',
        },
      );
    });

    test('catalog exposes only approved names and payload keys', () {
      final List<AnalyticsEvent> catalog = [
        AnalyticsEvent.onboardingStarted,
        AnalyticsEvent.onboardingCompleted,
        AnalyticsEvent.authSignedUp,
        AnalyticsEvent.authSignedIn,
        AnalyticsEvent.walletCreated,
        AnalyticsEvent.transactionCreated(TransactionAnalyticsType.transfer),
        AnalyticsEvent.reportViewed,
        AnalyticsEvent.transactionEdited,
        AnalyticsEvent.transactionDeleted,
        AnalyticsEvent.syncFailed,
        AnalyticsEvent.exportRequested,
        AnalyticsEvent.accountDeletionRequested,
        AnalyticsEvent.notificationsOptIn,
        AnalyticsEvent.aiOptIn,
        AnalyticsEvent.bankConnectStarted,
      ];

      expect(
        catalog.map((AnalyticsEvent event) => event.name),
        <String>[
          'onboarding_started',
          'onboarding_completed',
          'auth_signed_up',
          'auth_signed_in',
          'wallet_created',
          'transaction_created',
          'report_viewed',
          'transaction_edited',
          'transaction_deleted',
          'sync_failed',
          'export_requested',
          'account_deletion_requested',
          'notifications_opt_in',
          'ai_opt_in',
          'bank_connect_started',
        ],
      );
      for (final AnalyticsEvent event in catalog) {
        expect(
          event.toPayload().keys,
          everyElement(isIn(<String>{'event', 'schema_version', 'type'})),
        );
      }
    });
  });
}

Map<String, Object> _payloadFrom(String message) {
  const String prefix = 'analytics ';
  expect(message, startsWith(prefix));
  return (jsonDecode(message.substring(prefix.length)) as Map<String, dynamic>)
      .cast<String, Object>();
}

class _RecordingLogger implements AppLogger {
  final List<String> debugMessages = [];

  @override
  void debug(String message) => debugMessages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}
}
