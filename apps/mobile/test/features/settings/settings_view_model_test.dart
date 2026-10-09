import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/debug_analytics_service.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/domain/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../auth/fakes.dart';
import 'fakes.dart';

void main() {
  late MemoryPreferences preferences;
  late MemoryVault vault;
  late FakeBiometrics biometrics;
  late RecordingAnalytics analytics;
  late RecordingLogger logger;
  late AuthRepositoryImpl auth;
  late DefaultSettingsViewModel model;

  setUp(() {
    preferences = MemoryPreferences();
    vault = MemoryVault();
    biometrics = FakeBiometrics();
    analytics = RecordingAnalytics();
    logger = RecordingLogger();
    auth = AuthRepositoryImpl(FakeApi(), vault, biometrics);
    model = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(preferences)),
      DefaultAuthUseCases(auth),
      analytics,
    );
  });

  Future<void> unlockWithPin() async {
    await auth.submit(AuthAction.login, {
      'email': 'user@example.com',
      'password': 'password long enough',
    });
    await auth.setupPin('123456', false, 'unlock');
  }

  test(
    'loaded theme is applied and a failed save keeps the previous one',
    () async {
      preferences.value = encodePreferences(
        const AppPreferences(theme: AppThemePreference.dark),
      );
      await model.load();
      expect(model.theme, AppThemePreference.dark);
      preferences.fail = true;
      await model.setTheme(AppThemePreference.system);
      expect(model.theme, AppThemePreference.dark);
      expect(model.failure?.code, SettingsError.storage);
    },
  );

  test(
    'onboarding emits each catalog event once for finish and skip',
    () async {
      await model.load();
      model.beginOnboarding();
      model.beginOnboarding();
      expect(await model.completeOnboarding(), isTrue);
      expect(await model.completeOnboarding(), isTrue);
      expect(analytics.events, [
        AnalyticsEvent.onboardingStarted,
        AnalyticsEvent.onboardingCompleted,
      ]);
      model.beginOnboarding();
      expect(analytics.events, hasLength(2));
      expect(model.onboardingCompleted, isTrue);
      expect(model.theme, AppThemePreference.light);
    },
  );

  test('feedback body is not written to analytics or the logger', () async {
    const secret = 'secret-feedback-body';
    final service = DebugAnalyticsService(logger);
    final text = model.prepareFeedback(FeedbackKind.problem, '  $secret  ');
    expect(text, contains(secret));
    expect(model.prepareFeedback(FeedbackKind.idea, '   '), isNull);
    service.track(AnalyticsEvent.onboardingStarted);
    expect(logger.messages.single.contains(secret), isFalse);
    expect(analytics.events, isEmpty);
    expect(text!.contains('@'), isFalse);
  });

  test('a failed biometric confirmation does not flip the flag', () async {
    await unlockWithPin();
    await model.refreshBiometrics();
    expect(model.biometricHardware, isTrue);
    expect(model.biometricEnabled, isFalse);
    biometrics.accepted = false;
    await model.setBiometricEnabled(true, 'unlock');
    expect(model.biometricEnabled, isFalse);
    expect(model.biometricFailure?.code, AuthError.unavailable);
    expect(jsonDecode(vault.value!)['biometrics'], false);
    biometrics.accepted = true;
    await model.setBiometricEnabled(true, 'unlock');
    expect(model.biometricEnabled, isTrue);
    final calls = biometrics.calls;
    await model.setBiometricEnabled(false, 'unlock');
    expect(model.biometricEnabled, isFalse);
    expect(biometrics.calls, calls);
  });
}
