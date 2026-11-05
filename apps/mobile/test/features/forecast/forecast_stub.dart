import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';
import 'package:mobile/features/forecast/domain/balance_forecast.dart';
import 'package:mobile/features/forecast/domain/forecast_use_cases.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/recurring/domain/recurring_rule.dart';
import 'package:mobile/features/recurring/domain/recurring_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../home/fixtures.dart' show b, wallet;
import '../profile/fakes.dart';
import '../categories/e1_stub.dart' show StubCategoryViewModel;
import '../recurring/recurring_stub.dart'
    show FakeRecurringUseCases, recCategories, rule;
import '../wallets/d1_stub.dart' show StubWalletViewModel;

/// Recurring items of the Forecast artboard (Lương, Tiền nhà, Tiền điện,
/// Học phí).
List<RecurringRule> forecastRules() => [
  rule(
    'salary',
    'Lương',
    type: 'income',
    amount: 18500000,
    next: '2026-12-05',
    start: '2026-10-05',
  ),
  rule(
    'rent',
    'Tiền nhà',
    amount: -6000000,
    next: '2026-12-01',
    categoryId: 'home',
  ),
  rule(
    'power',
    'Tiền điện',
    mode: 'remind',
    amount: -850000,
    next: '2026-11-05',
    start: '2026-10-05',
    amountKind: 'estimated',
    categoryId: 'power',
  ),
  rule(
    'school',
    'Học phí',
    mode: 'remind',
    amount: -6230000,
    next: '2026-11-15',
    start: '2026-11-15',
    end: '2026-11-15',
    categoryId: 'school',
  ),
];

const _ids = ['salary', 'rent', 'power', 'school'];

/// The numbers on the artboard for the default input, otherwise a flat
/// +11.65tr per month with each switched-off rule taken out.
class FakeForecastUseCases implements ForecastUseCases {
  final calls = <({int months, BigInt? start, Set<String> excluded})>[];
  AuthFailure? failure;

  static const _wallets = 48250000;

  @override
  Future<Either<AuthFailure, BalanceForecast>> load({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    Set<String> excludeRuleIds = const {},
  }) async {
    calls.add((
      months: months,
      start: startingBalanceMinor,
      excluded: excludeRuleIds,
    ));
    if (failure != null) return left(failure!);
    final start = startingBalanceMinor ?? b(_wallets);
    final plain = startingBalanceMinor == null && excludeRuleIds.isEmpty;
    final names = ['2026-11', '2026-12', '2027-01'];
    var opening = start;
    final list = <ForecastMonth>[];
    for (var i = 0; i < months; i++) {
      final month = i < 3
          ? names[i]
          : '${2027 + (i - 2) ~/ 12}-${((i - 2) % 12 + 1).toString().padLeft(2, '0')}';
      var income = b(18500000);
      var expense = b(-6850000 - (i == 0 ? 6230000 : 0));
      if (excludeRuleIds.contains('salary')) income = BigInt.zero;
      if (excludeRuleIds.contains('rent')) expense += b(6000000);
      if (excludeRuleIds.contains('power')) expense += b(850000);
      if (i == 0 && excludeRuleIds.contains('school')) expense += b(6230000);
      var closing = opening + income + expense;
      if (plain && months == 3) {
        closing = b([65900000, 77600000, 89200000][i]);
        income = closing - opening;
        expense = BigInt.zero;
      }
      list.add(
        ForecastMonth(
          month: month,
          openingMinor: opening,
          incomeMinor: income,
          expenseMinor: expense,
          closingMinor: closing,
        ),
      );
      opening = closing;
    }
    return right(
      BalanceForecast(
        currencyCode: 'VND',
        from: '2026-11-03',
        to: '2027-01-31',
        startingBalanceMinor: start,
        months: list,
        assumptions: ForecastAssumptions(
          fromWallets: startingBalanceMinor == null,
          includedRuleIds: [
            for (final id in _ids)
              if (!excludeRuleIds.contains(id)) id,
          ],
          excludedRuleIds: [
            for (final id in _ids)
              if (excludeRuleIds.contains(id)) id,
          ],
          otherCurrencyRuleIds: const [],
        ),
      ),
    );
  }
}

/// Four wallets that add up to 48.250.000, plus a card the forecast skips.
class ForecastWallets extends StubWalletViewModel {
  ForecastWallets()
    : super(
        wallets: [
          wallet('vcb', 'Vietcombank', balance: 30000000),
          wallet('tcb', 'Techcombank', balance: 10000000),
          wallet('momo', 'MoMo', balance: 5000000),
          wallet('cash', 'Tiền mặt', balance: 3250000),
        ],
      );
}

class ForecastHarness {
  ForecastHarness._(this.cases, this.recurring, this.app, this.router);
  final FakeForecastUseCases cases;
  final FakeRecurringUseCases recurring;
  final Widget app;
  final GoRouter router;
}

Future<ForecastHarness> forecastApp(
  Widget page, {
  bool dark = false,
  double scale = 1,
  FakeForecastUseCases? cases,
  List<RecurringRule>? rules,
}) async {
  await getIt.reset();
  final repo = AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics());
  final auth = DefaultAuthViewModel(DefaultAuthUseCases(repo))
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
    ProfileUseCases(profiles),
    auth,
    exportCase(repo),
  );
  await profile.load();
  final forecast = cases ?? FakeForecastUseCases();
  final recurring = FakeRecurringUseCases(rules: rules ?? forecastRules());
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(ForecastWallets())
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<CategoryViewModel>(
      StubCategoryViewModel(categories: recCategories()),
    )
    ..registerSingleton<ForecastUseCases>(forecast)
    ..registerSingleton<RecurringUseCases>(recurring);
  Widget scaled(Widget child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: child,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/page', builder: (context, state) => scaled(page)),
      GoRoute(path: '/reports', builder: (context, state) => const SizedBox()),
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
  return ForecastHarness._(forecast, recurring, app, router);
}
