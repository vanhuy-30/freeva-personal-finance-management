import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/domain/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/core/router/settings_redirect.dart';

import 'fakes.dart';

void main() {
  test('preferences round-trip and reject unknown payloads', () {
    const saved = AppPreferences(
      theme: AppThemePreference.dark,
      onboardingCompleted: true,
    );
    expect(decodePreferences(encodePreferences(saved)).theme, saved.theme);
    expect(
      decodePreferences(encodePreferences(saved)).onboardingCompleted,
      isTrue,
    );
    expect(() => decodePreferences('{"theme":"neon"}'), throwsFormatException);
    expect(
      () => decodePreferences(
        '{"theme":"light","onboardingCompleted":true,"email":"a@b.c"}',
      ),
      throwsFormatException,
    );
  });

  test(
    'theme save keeps the onboarding flag and survives a new store read',
    () async {
      final vault = MemoryPreferences();
      final cases = DefaultSettingsUseCases(SettingsRepositoryImpl(vault));
      final loaded = await cases.load();
      final initial = loaded.getOrElse(() => const AppPreferences());
      expect(initial.theme, AppThemePreference.light);
      final saved = await cases.save(
        initial.copyWith(theme: AppThemePreference.system),
      );
      expect(
        saved.getOrElse(() => const AppPreferences()).theme,
        AppThemePreference.system,
      );
      final again = DefaultSettingsUseCases(SettingsRepositoryImpl(vault));
      final restored = (await again.load()).getOrElse(
        () => const AppPreferences(),
      );
      expect(restored.theme, AppThemePreference.system);
      expect(restored.onboardingCompleted, isFalse);
    },
  );

  test('feedback text stays local and rejects empty or oversized messages', () {
    final cases = DefaultSettingsUseCases(
      SettingsRepositoryImpl(MemoryPreferences()),
    );
    expect(cases.feedbackText(FeedbackKind.idea, '   ').isLeft(), isTrue);
    expect(
      cases.feedbackText(FeedbackKind.problem, 'x' * 2001).isLeft(),
      isTrue,
    );
    final text = cases
        .feedbackText(FeedbackKind.problem, '  lamp broken  ')
        .getOrElse(() => '');
    expect(text, 'Freeva $appVersionLabel\nproblem\nlamp broken');
    expect(text.contains('@'), isFalse);
    expect(cases.feedbackText(FeedbackKind.idea, 'x' * 2000).isRight(), isTrue);
  });

  test('onboarding redirect waits for an unlocked session', () {
    expect(
      settingsRedirect(
        stage: AuthStage.unlocked,
        onboardingCompleted: false,
        path: '/splash',
      ),
      isNull,
    );
    expect(
      settingsRedirect(
        stage: AuthStage.unlocked,
        onboardingCompleted: false,
        path: '/home',
      ),
      '/onboarding',
    );
    expect(
      settingsRedirect(
        stage: AuthStage.unlocked,
        onboardingCompleted: false,
        path: '/onboarding',
      ),
      isNull,
    );
    expect(
      settingsRedirect(
        stage: AuthStage.signedOut,
        onboardingCompleted: false,
        path: '/home',
      ),
      isNull,
    );
    expect(
      settingsRedirect(
        stage: AuthStage.locked,
        onboardingCompleted: false,
        path: '/settings',
      ),
      isNull,
    );
    expect(
      settingsRedirect(
        stage: AuthStage.unlocked,
        onboardingCompleted: true,
        path: '/onboarding',
      ),
      '/home',
    );
  });
}
