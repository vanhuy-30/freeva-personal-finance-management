import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
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
import 'package:mobile/features/settings/presentation/pages/feedback_page.dart';
import 'package:mobile/features/settings/presentation/pages/legal_page.dart';
import 'package:mobile/features/settings/presentation/pages/onboarding_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:mobile/features/settings/presentation/theme_mode.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_appearance.dart';

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
          ..stage = AuthStage.unlocked;
    analytics = RecordingAnalytics();
    settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
      analytics,
    );
    await settings.load();
    profile = DefaultProfileViewModel(ProfileUseCases(MemoryProfiles()), auth);
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

  testWidgets('dark theme applies after it is selected', (tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: settings,
        builder: (context, _) => MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: themeModeFor(settings.theme),
          locale: const Locale('en'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  SettingsAppearance(model: settings),
                  Text(Theme.of(context).brightness.name),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('light'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(settings.theme, AppThemePreference.dark);
    expect(find.text('dark'), findsOneWidget);
  });

  testWidgets('skip completes onboarding once', (tester) async {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('home-ready')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('home-ready'), findsOneWidget);
    expect(analytics.events, [
      AnalyticsEvent.onboardingStarted,
      AnalyticsEvent.onboardingCompleted,
    ]);
  });

  testWidgets('empty feedback is rejected and a valid note is copied', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        if (call.method == 'Clipboard.getData') {
          return <String, dynamic>{'text': copied};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(framed(const FeedbackPage(), locale: 'en'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy feedback'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a message of up to 2000 characters.'),
      findsOneWidget,
    );
    expect(copied, isNull);
    await tester.enterText(find.byType(TextField), 'lamp is fine');
    await tester.tap(find.text('Copy feedback'));
    await tester.pumpAndSettle();
    expect(copied, contains('lamp is fine'));
    expect(copied, contains('idea'));
    expect(copied!.contains('@'), isFalse);
    expect(find.textContaining('does not send this message'), findsOneWidget);
  });

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
      const FeedbackPage(),
      const LegalPage(document: LegalDocument.terms),
      const LegalPage(document: LegalDocument.privacy),
      const OnboardingPage(),
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
