import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/domain/transactions_csv_export_use_case.dart';
import 'package:mobile/features/profile/presentation/viewmodels/data_export_view_model.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../auth/fakes.dart';
import '../home/fixtures.dart' show wallet;
import 'fakes.dart';
import '../../support/server_config_fixture.dart';

class FakeExportWallets implements WalletUseCases {
  List<Wallet> wallets = [
    wallet('vcb', 'Vietcombank', balance: 17288000),
    wallet('cash', 'Tiền mặt', balance: 12300000),
    wallet('old', 'Ví cũ', archived: true),
  ];
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(wallets);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExportTransactions implements TransactionUseCases {
  int total = 248;
  AuthFailure? failure;
  final queries = <TransactionQuery>[];
  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async {
    queries.add(query);
    if (failure != null) return left(failure!);
    return right(TransactionListPage(legs: const [], page: 1, total: total));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExportProfile implements ProfileViewModel {
  int exports = 0;
  bool shared = true;
  @override
  AuthFailure? failure;
  @override
  Future<bool> exportData() async {
    exports++;
    return shared;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeExportAuth implements AuthViewModel {
  int expired = 0;
  @override
  void sessionExpired() => expired++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ExportHarness {
  ExportHarness._(
    this.model,
    this.api,
    this.sharer,
    this.transactions,
    this.profile,
    this.auth,
  );
  final DefaultDataExportViewModel model;
  final FakeApi api;
  final FakeSharer sharer;
  final FakeExportTransactions transactions;
  final FakeExportProfile profile;
  final FakeExportAuth auth;

  static Future<ExportHarness> create() async {
    final api = FakeApi();
    final sharer = FakeSharer();
    final repo = AuthRepositoryImpl(
      api,
      MemoryVault(),
      FakeBiometrics(),
      testServerConfigModel(),
    );
    await repo.submit(AuthAction.login, {
      'email': 'user@example.com',
      'password': 'password long enough',
    });
    final transactions = FakeExportTransactions();
    final profile = FakeExportProfile();
    final auth = FakeExportAuth();
    final model = DefaultDataExportViewModel(
      ProfileUseCases(MemoryProfiles(), testServerConfigModel()),
      FakeExportWallets(),
      transactions,
      TransactionsCsvExportUseCase(repo, sharer),
      profile,
      auth,
      testServerConfigModel(),
    );
    return ExportHarness._(model, api, sharer, transactions, profile, auth);
  }
}

/// The page on its own router, backed by the real view model.
Future<(ExportHarness, Widget)> exportApp(
  Widget page, {
  bool dark = false,
  double scale = 1,
}) async {
  registerTestServerConfig();
  final h = await ExportHarness.create();
  getIt.registerFactory<DataExportViewModel>(() => h.model);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: page,
        ),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
    ],
  );
  return (
    h,
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      routerConfig: router,
    ),
  );
}
