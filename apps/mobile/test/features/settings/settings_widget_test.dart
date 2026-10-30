import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/app_preferences.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/pages/faq_page.dart';
import 'package:mobile/features/settings/presentation/pages/legal_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../auth/fakes.dart';
import '../profile/fakes.dart';
import 'fakes.dart';

void main() {
  late DefaultAuthViewModel auth;
  late DefaultSettingsViewModel settings;
  late DefaultProfileViewModel profile;
  late RecordingAnalytics analytics;

  setUp(() async {
    await getIt.reset();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..ready = true
          ..stage = AuthStage.unlocked
          ..hasPin = true;
    analytics = RecordingAnalytics();
    settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
      analytics,
    );
    await settings.load();
    profile = DefaultProfileViewModel(
      ProfileUseCases(MemoryProfiles()),
      auth,
      exportCase(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
    );
    await profile.load();
    getIt.registerSingleton<AuthViewModel>(auth);
    getIt.registerSingleton<SettingsViewModel>(settings);
    getIt.registerSingleton<ProfileViewModel>(profile);
  });

  tearDown(() async {
    settings.dispose();
    profile.dispose();
    auth.dispose();
    await getIt.reset();
  });

  Widget framed(Widget child, {String locale = 'vi', double scale = 1}) =>
      MaterialApp(
        locale: Locale(locale),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      );

  testWidgets('settings help screens fit a small display in both locales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pages = [
      const SettingsPage(),
      const FaqPage(),
      const LegalPage(document: LegalDocument.terms),
      const LegalPage(document: LegalDocument.privacy),
    ];
    for (final locale in ['vi', 'en']) {
      for (final page in pages) {
        await tester.pumpWidget(framed(page, locale: locale, scale: 2));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}
