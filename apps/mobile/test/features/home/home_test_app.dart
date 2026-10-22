import 'package:flutter/material.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/home/presentation/pages/home_page.dart';
import 'package:mobile/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../auth/fakes.dart';
import 'fixtures.dart';
import 'home_fakes.dart';

/// Registers [model] (plus an unlocked auth model for the session banner)
/// and returns the Overview page in a themed app.
Future<Widget> homeApp(
  StubHomeViewModel model, {
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  getIt.registerSingleton<HomeViewModel>(model);
  getIt.registerSingleton<AuthViewModel>(
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )
      ..stage = AuthStage.unlocked
      ..ready = true,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: const HomePage(),
    ),
  );
}

/// The eight designed states (B1–B8).
StubHomeViewModel homeState(String name) => switch (name) {
  'hidden' => StubHomeViewModel(data: overview(), balancesHidden: true),
  'multi' => StubHomeViewModel(
    data: overview(
      net: [worth('VND', 48250000), worth('USD', 125000)],
      wallets: [
        wallet('vcb', 'Vietcombank'),
        wallet('cash', 'Tiền mặt'),
        wallet('momo', 'MoMo'),
        wallet('tcb', 'Techcombank'),
        wallet('usd', 'Ngoại tệ', currency: 'USD'),
      ],
      flow: month(extra: [usdSpend()]),
    ),
  ),
  'debt' => StubHomeViewModel(
    data: overview(
      wallets: [
        wallet('vcb', 'Vietcombank'),
        wallet(
          'tcb',
          'Thẻ TCB',
          type: WalletType.credit,
          balance: -6200000,
          limit: 20000000,
          dueDay: 25,
        ),
      ],
    ),
  ),
  'newMonth' => StubHomeViewModel(
    data: overview(
      flow: month(income: 0, expense: 0, rows: const [], from: '2026-11-01'),
      previous: month(),
      rows: const [],
    ),
  ),
  'loading' => StubHomeViewModel(status: HomeStatus.loading),
  'offline' => StubHomeViewModel(status: HomeStatus.offline, data: overview()),
  'error' => StubHomeViewModel(status: HomeStatus.error),
  _ => StubHomeViewModel(data: overview()),
};
