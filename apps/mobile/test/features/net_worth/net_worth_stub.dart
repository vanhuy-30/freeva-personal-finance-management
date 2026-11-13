import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/net_worth/domain/net_worth_use_cases.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../forecast/forecast_stub.dart' show ForecastWallets;
import '../home/fixtures.dart' show b;
import '../profile/fakes.dart';

/// Six monthly points of the Q.1 board: 872,4 triệu to 929,7 triệu.
NetWorthSeries sixMonths(NetWorthWindow window) {
  const nets = [
    872400000,
    880000000,
    895000000,
    901000000,
    915000000,
    929700000,
  ];
  return NetWorthSeries(
    window: window,
    currency: 'VND',
    points: [
      for (var i = 0; i < nets.length; i++)
        NetWorthPoint(
          asOf:
              '2026-${(i + 6).toString().padLeft(2, '0')}-${i == 5 ? '06' : '30'}',
          assetsMinor: b(nets[i] + 12000000),
          liabilitiesMinor: b(-12000000),
          netWorthMinor: b(nets[i]),
          investmentMinor: b(nets[i] - 40000000),
        ),
    ],
  );
}

class FakeNetWorthUseCases implements NetWorthUseCases {
  final windows = <NetWorthWindow>[];
  AuthFailure? failure;
  NetWorthSeries Function(NetWorthWindow window) build = sixMonths;

  @override
  Future<Either<AuthFailure, NetWorthSeries>> load(
    NetWorthWindow window, {
    required String currency,
  }) async {
    windows.add(window);
    return failure != null ? left(failure!) : right(build(window));
  }
}

Future<({FakeNetWorthUseCases cases, Widget app, GoRouter router})> netWorthApp(
  Widget page, {
  bool dark = false,
  FakeNetWorthUseCases? cases,
}) async {
  await getIt.reset();
  registerTestServerConfig();
  final repo = AuthRepositoryImpl(
    FakeApi(),
    MemoryVault(),
    FakeBiometrics(),
    testServerConfigModel(),
  );
  final auth =
      DefaultAuthViewModel(DefaultAuthUseCases(repo, testServerConfigModel()))
        ..stage = AuthStage.unlocked
        ..hasPin = true
        ..ready = true;
  final profiles = MemoryProfiles()
    ..value = const Profile(
      locale: 'vi',
      currency: 'VND',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalDay: 1,
      version: 1,
      displayName: 'Minh',
    );
  final profile = DefaultProfileViewModel(
    ProfileUseCases(profiles, testServerConfigModel()),
    auth,
    exportCase(repo),
  );
  await profile.load();
  final fake = cases ?? FakeNetWorthUseCases();
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(ForecastWallets())
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<NetWorthUseCases>(fake);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/page', builder: (context, state) => page),
      GoRoute(path: '/me', builder: (context, state) => const SizedBox()),
    ],
  );
  final app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: router,
  );
  return (cases: fake, app: app, router: router);
}
