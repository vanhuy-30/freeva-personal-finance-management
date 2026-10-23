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
  });

  final AppThemePreference theme;
  final bool onboardingCompleted;
  final bool balancesHidden;
  final bool sessionAlertsEnabled;
  final bool notificationPrompted;
  final bool notificationsOptInTracked;

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? onboardingCompleted,
    bool? balancesHidden,
    bool? sessionAlertsEnabled,
    bool? notificationPrompted,
    bool? notificationsOptInTracked,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    balancesHidden: balancesHidden ?? this.balancesHidden,
    sessionAlertsEnabled: sessionAlertsEnabled ?? this.sessionAlertsEnabled,
    notificationPrompted: notificationPrompted ?? this.notificationPrompted,
    notificationsOptInTracked:
        notificationsOptInTracked ?? this.notificationsOptInTracked,
  );
}
