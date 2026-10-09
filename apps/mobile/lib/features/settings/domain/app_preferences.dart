const String appVersionLabel = '0.0.1+1';

enum AppThemePreference { light, dark, system }

enum FeedbackKind { idea, problem }

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
  });

  final AppThemePreference theme;
  final bool onboardingCompleted;

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? onboardingCompleted,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
  );
}
