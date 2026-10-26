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
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
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
      ..hasPin = true
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

/// The designed states (B1–B8) plus the first-run Overview (A1.7).
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
    debtGoal: true,
    data: overview(
      net: [worth('VND', 41850000)],
      wallets: [
        wallet('vcb', 'Vietcombank'),
        wallet('cash', 'Tiền mặt', type: WalletType.cash),
        wallet(
          'main',
          'Thẻ chính',
          type: WalletType.credit,
          balance: -15600000,
          limit: 20000000,
          dueDay: 25,
        ),
        wallet(
          'travel',
          'Thẻ du lịch',
          type: WalletType.credit,
          balance: -1800000,
          limit: 10000000,
          dueDay: 12,
        ),
      ],
    ),
  ),
  // 1/11: nothing recorded this month yet; last month's rows are still the
  // most recent ones, so the first-run checklist does not show.
  'newMonth' => StubHomeViewModel(
    data: overview(
      net: [worth('VND', 57430000)],
      flow: month(
        income: 0,
        expense: 0,
        rows: const [],
        from: '2026-11-01',
        to: '2026-11-30',
      ),
      previous: month(expense: 11480000),
    ),
  )..today = DateTime(2026, 11, 1, 9, 30),
  'loading' => StubHomeViewModel(status: HomeStatus.loading),
  'offline' => StubHomeViewModel(
    status: HomeStatus.offline,
    data: overview(),
    pending: [highlands()],
  ),
  'error' => StubHomeViewModel(status: HomeStatus.error),
  'firstRun' => StubHomeViewModel(
    hasPin: false,
    data: overview(
      net: [worth('VND', 850000)],
      wallets: [
        wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 850000),
      ],
      flow: month(income: 0, expense: 0, rows: const []),
      rows: const [],
    ),
  ),
  _ => StubHomeViewModel(data: overview()),
};

/// A coffee still waiting to sync (offline board).
SyncQueueItem highlands() => SyncQueueItem(
  opId: 'op-1',
  clientId: '11111111-1111-4111-8111-111111111111',
  action: SyncAction.create,
  type: TransactionType.expense,
  occurredOn: '2026-10-21',
  categoryId: 'coffee',
  merchant: 'Highlands',
  legs: const [
    SyncLeg(
      clientId: '22222222-2222-4222-8222-222222222222',
      accountId: 'cash',
      currencyCode: 'VND',
      amountMinor: '-55000',
    ),
  ],
  createdAt: DateTime(2026, 10, 21, 9, 12),
  retryCount: 0,
  status: SyncItemStatus.pending,
  review: false,
);
