enum TransactionAnalyticsType {
  income,
  expense,
  transfer,
}

/// A privacy-safe analytics event from Freeva's approved catalog.
///
/// Constructors stay private so callers cannot attach arbitrary properties
/// such as an email address, account number, balance, or transaction amount.
class AnalyticsEvent {
  const AnalyticsEvent._(this.name, [this._properties = const {}]);

  static const int schemaVersion = 1;

  static const AnalyticsEvent onboardingStarted = AnalyticsEvent._(
    'onboarding_started',
  );
  static const AnalyticsEvent onboardingCompleted = AnalyticsEvent._(
    'onboarding_completed',
  );
  static const AnalyticsEvent authSignedUp = AnalyticsEvent._(
    'auth_signed_up',
  );
  static const AnalyticsEvent authSignedIn = AnalyticsEvent._(
    'auth_signed_in',
  );
  static const AnalyticsEvent walletCreated = AnalyticsEvent._(
    'wallet_created',
  );
  static const AnalyticsEvent reportViewed = AnalyticsEvent._(
    'report_viewed',
  );
  static const AnalyticsEvent transactionEdited = AnalyticsEvent._(
    'transaction_edited',
  );
  static const AnalyticsEvent transactionDeleted = AnalyticsEvent._(
    'transaction_deleted',
  );
  static const AnalyticsEvent syncFailed = AnalyticsEvent._('sync_failed');
  static const AnalyticsEvent exportRequested = AnalyticsEvent._(
    'export_requested',
  );
  static const AnalyticsEvent accountDeletionRequested = AnalyticsEvent._(
    'account_deletion_requested',
  );
  static const AnalyticsEvent notificationsOptIn = AnalyticsEvent._(
    'notifications_opt_in',
  );
  static const AnalyticsEvent aiOptIn = AnalyticsEvent._('ai_opt_in');
  static const AnalyticsEvent bankConnectStarted = AnalyticsEvent._(
    'bank_connect_started',
  );

  factory AnalyticsEvent.transactionCreated(TransactionAnalyticsType type) {
    return AnalyticsEvent._('transaction_created', {'type': type.name});
  }

  final String name;
  final Map<String, String> _properties;

  Map<String, Object> toPayload() => Map<String, Object>.unmodifiable({
        'event': name,
        'schema_version': schemaVersion,
        ..._properties,
      });
}
