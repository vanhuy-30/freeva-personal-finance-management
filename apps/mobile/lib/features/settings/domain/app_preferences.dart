const String appVersionLabel = '0.0.1+1';

enum AppThemePreference { light, dark, system }

enum LegalDocument { terms, privacy }

enum SettingsError { storage, invalidInput }

class SettingsFailure {
  const SettingsFailure(this.code);
  final SettingsError code;
}

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.light,
    this.onboardingCompleted = false,
    this.balancesHidden = false,
    this.sessionAlertsEnabled = true,
    this.notificationPrompted = false,
    this.notificationsOptInTracked = false,
    this.welcomeSeen = false,
    this.budgetDraftMinor,
  });

  final AppThemePreference theme;
  final bool onboardingCompleted;
  final bool balancesHidden;
  final bool sessionAlertsEnabled;
  final bool notificationPrompted;
  final bool notificationsOptInTracked;

  /// The Welcome screen was shown once; later launches open on Đăng nhập.
  final bool welcomeSeen;

  /// Monthly budget typed during first-run setup, in minor units of the
  /// account currency. Kept on the device until the budget module
  /// (`BE-P2-E02`) can take it; null when skipped.
  final int? budgetDraftMinor;
  static const _keep = Object();

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? onboardingCompleted,
    bool? balancesHidden,
    bool? sessionAlertsEnabled,
    bool? notificationPrompted,
    bool? notificationsOptInTracked,
    bool? welcomeSeen,
    Object? budgetDraftMinor = _keep,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    balancesHidden: balancesHidden ?? this.balancesHidden,
    sessionAlertsEnabled: sessionAlertsEnabled ?? this.sessionAlertsEnabled,
    notificationPrompted: notificationPrompted ?? this.notificationPrompted,
    notificationsOptInTracked:
        notificationsOptInTracked ?? this.notificationsOptInTracked,
    welcomeSeen: welcomeSeen ?? this.welcomeSeen,
    budgetDraftMinor: identical(budgetDraftMinor, _keep)
        ? this.budgetDraftMinor
        : budgetDraftMinor as int?,
  );
}
