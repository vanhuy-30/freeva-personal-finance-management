import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../auth/fakes.dart';
import '../profile/fakes.dart';
import 'fakes.dart';

/// Everything the Cá nhân screens read: a signed-in, PIN-protected device
/// (user@example.com), real view models over in-memory storage.
class G1 {
  late final FakeApi api;
  late final MemoryVault vault;
  late final FakeBiometrics biometrics;
  late final AuthRepositoryImpl repository;
  late final DefaultAuthViewModel auth;
  late final DefaultSettingsViewModel settings;
  late final DefaultProfileViewModel profile;
  late final MemoryProfiles profiles;
  final preferences = MemoryPreferences();

  static Future<G1> create({
    String? displayName = 'Minh',
    String email = 'minh@gmail.com',
  }) async {
    tzdata.initializeTimeZones();
    await getIt.reset();
    final g = G1();
    g.api = FakeApi();
    g.vault = MemoryVault();
    g.biometrics = FakeBiometrics();
    g.repository = AuthRepositoryImpl(g.api, g.vault, g.biometrics);
    await g.repository.submit(AuthAction.login, {
      'email': email,
      'password': 'password long enough',
    });
    await g.repository.setupPin('123456', true, 'unlock');
    final cases = DefaultAuthUseCases(g.repository);
    g.auth = DefaultAuthViewModel(cases)
      ..ready = true
      ..stage = AuthStage.unlocked;
    g.settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(g.preferences)),
      cases,
      RecordingAnalytics(),
    );
    await g.settings.load();
    await g.settings.refreshBiometrics();
    g.profiles = MemoryProfiles()
      ..value = Profile(
        locale: 'vi',
        currency: 'VND',
        timezone: 'Asia/Ho_Chi_Minh',
        fiscalDay: 1,
        version: 1,
        displayName: displayName,
      );
    g.profile = DefaultProfileViewModel(ProfileUseCases(g.profiles), g.auth);
    await g.profile.load();
    g.api.sessionItems = [
      {
        'id': 'current',
        'createdAt': DateTime(2026, 10, 2).toIso8601String(),
        'expiresAt': DateTime(2026, 11, 1).toIso8601String(),
        'current': true,
      },
      {
        'id': 'phone',
        'createdAt': DateTime(2026, 10, 18).toIso8601String(),
        'expiresAt': DateTime(2026, 11, 17).toIso8601String(),
        'current': false,
      },
    ];
    getIt
      ..registerSingleton<AuthViewModel>(g.auth)
      ..registerSingleton<AuthUseCases>(cases)
      ..registerSingleton<SettingsViewModel>(g.settings)
      ..registerSingleton<ProfileViewModel>(g.profile);
    return g;
  }

  void dispose() {
    settings.dispose();
    profile.dispose();
    auth.dispose();
  }

  /// [page] at `/`; the routes it pushes to open a named placeholder.
  Widget app(
    Widget page, {
    bool dark = false,
    double scale = 1,
    List<GoRoute> routes = const [],
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => page),
        for (final path in [
          '/wallets',
          '/categories',
          '/profile',
          '/me/security',
          '/me/sessions',
          '/me/security/pin',
          '/me/security/password',
          '/help/faq',
          '/help/feedback',
          '/help/legal',
        ])
          GoRoute(
            path: path,
            builder: (_, __) => Scaffold(body: Text('PAGE $path')),
          ),
        ...routes,
      ],
    );
    return ListenableBuilder(
      listenable: profile,
      builder: (context, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: Locale(profile.locale),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: child!,
        ),
        routerConfig: router,
      ),
    );
  }
}
