import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/domain/settings_repository.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';

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
    const hidden = AppPreferences(
      balancesHidden: true,
      sessionAlertsEnabled: false,
      notificationPrompted: true,
      notificationsOptInTracked: true,
    );
    final firstRun = decodePreferences(
      encodePreferences(
        const AppPreferences(welcomeSeen: true, budgetDraftMinor: 10000000),
      ),
    );
    expect(firstRun.welcomeSeen, isTrue);
    expect(firstRun.budgetDraftMinor, 10000000);
    expect(
      decodePreferences(encodePreferences(saved)).budgetDraftMinor,
      isNull,
    );
    expect(
      () => decodePreferences(
        '{"theme":"dark","onboardingCompleted":false,"budgetDraftMinor":-1}',
      ),
      throwsFormatException,
    );
    final restored = decodePreferences(encodePreferences(hidden));
    expect(restored.balancesHidden, isTrue);
    expect(restored.sessionAlertsEnabled, isFalse);
    expect(restored.notificationPrompted, isTrue);
    expect(restored.notificationsOptInTracked, isTrue);
    final legacy = decodePreferences(
      '{"theme":"dark","onboardingCompleted":false}',
    );
    expect(legacy.theme, AppThemePreference.dark);
    expect(legacy.balancesHidden, isFalse);
    expect(legacy.sessionAlertsEnabled, isTrue);
    expect(
      () => decodePreferences(
        '{"theme":"light","onboardingCompleted":true,"balancesHidden":"yes"}',
      ),
      throwsFormatException,
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
}
