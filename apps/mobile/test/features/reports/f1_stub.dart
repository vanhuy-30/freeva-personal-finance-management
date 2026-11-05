import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/analytics_service.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/domain/budget_use_cases.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../auth/fakes.dart';
import '../home/home_fakes.dart' show FakeProfileViewModel;

BigInt _b(int v) => BigInt.from(v);

CashflowCategoryRow _cat(
  String id,
  String name,
  int spend, {
  String? parent,
  String? parentName,
  int count = 3,
}) => CashflowCategoryRow(
  categoryId: id,
  parentId: parent,
  currency: 'VND',
  incomeMinor: BigInt.zero,
  expenseMinor: _b(-spend),
  transactionCount: count,
  name: name,
  parentName: parentName,
);

CashflowAccountRow _wallet(
  String id,
  String name,
  WalletType type,
  int income,
  int expense,
) => CashflowAccountRow(
  accountId: id,
  currency: 'VND',
  incomeMinor: _b(income),
  expenseMinor: _b(-expense),
  transferMinor: BigInt.zero,
  netMinor: _b(income - expense),
  name: name,
  type: type,
);

ReportPeriod _month(String from, String to) => ReportPeriod(
  kind: ReportPeriodKind.month,
  from: from,
  to: to,
  timezone: 'Asia/Ho_Chi_Minh',
  fiscalMonthStartDay: 1,
);

/// October 2026 as drawn in the canvas: 18,5tr in, 9,32tr out.
CashflowReport october() => CashflowReport(
  period: _month('2026-10-01', '2026-10-31'),
  totals: [
    CashflowTotal(
      currency: 'VND',
      incomeMinor: _b(18500000),
      expenseMinor: _b(-9320000),
      netMinor: _b(9180000),
    ),
  ],
  byCategory: [
    _cat('coffee', 'Cà phê', 1200000, parent: 'food', parentName: 'Ăn uống'),
    _cat('out', 'Ăn ngoài', 2341600, parent: 'food', parentName: 'Ăn uống'),
    _cat('rent', 'Nhà ở', 2236800),
    _cat('bus', 'Đi lại', 1677600),
    _cat('shop', 'Mua sắm', 600000),
    _cat('health', 'Sức khoẻ', 400000),
    _cat('fun', 'Giải trí', 350000),
    _cat('learn', 'Giáo dục', 250000),
    _cat('gift', 'Quà tặng', 150000),
    _cat('misc', 'Linh tinh', 114000),
    CashflowCategoryRow(
      categoryId: 'salary',
      parentId: null,
      currency: 'VND',
      incomeMinor: _b(18500000),
      expenseMinor: BigInt.zero,
      transactionCount: 1,
      name: 'Lương',
    ),
  ],
  byAccount: [
    _wallet('vcb', 'Vietcombank', WalletType.bank, 18500000, 712000),
    _wallet('card', 'Thẻ chính', WalletType.credit, 0, 4498000),
    _wallet('cash', 'Tiền mặt', WalletType.cash, 0, 2430000),
    _wallet('momo', 'MoMo', WalletType.ewallet, 500000, 1680000),
  ],
);

CashflowReport _empty(String from, String to) => CashflowReport(
  period: _month(from, to),
  totals: const [],
  byCategory: const [],
  byAccount: const [],
);

TrendReport _trend(ReportPeriodKind kind) {
  const spend = [7800000, 10600000, 8900000, 11200000, 9900000, 9320000];
  const starts = [
    '2026-05-01',
    '2026-06-01',
    '2026-07-01',
    '2026-08-01',
    '2026-09-01',
    '2026-10-01',
  ];
  return TrendReport(
    kind: kind,
    buckets: [
      for (var i = 0; i < spend.length; i++)
        TrendBucket(
          from: starts[i],
          to: starts[i],
          totals: [
            TrendTotal(
              currency: 'VND',
              incomeMinor: BigInt.zero,
              expenseMinor: _b(-spend[i]),
            ),
          ],
        ),
    ],
  );
}

/// Canned data: October 2026 (previous: September 9,9tr), anything else empty.
class StubReportCases implements ReportUseCases {
  @override
  Future<Either<AuthFailure, NamedCashflow>> loadCashflow(
    ReportPeriodQuery query,
  ) async {
    final current = query.on == null || query.on!.startsWith('2026-10');
    return right(
      NamedCashflow(
        currencies: const [WalletCurrency('VND', 0)],
        report: current ? october() : _empty('2026-03-01', '2026-03-31'),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, CashflowReport>> loadPrevious(
    ReportPeriod period,
  ) async => right(
    CashflowReport(
      period: _month('2026-09-01', '2026-09-30'),
      totals: [
        CashflowTotal(
          currency: 'VND',
          incomeMinor: BigInt.zero,
          expenseMinor: _b(-9900000),
          netMinor: _b(-9900000),
        ),
      ],
      byCategory: const [],
      byAccount: const [],
    ),
  );

  @override
  Future<Either<AuthFailure, NamedMonthReview>> loadMonthReview({
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, TrendReport>> loadTrend(
    ReportPeriodKind kind, {
    String? on,
  }) async => right(_trend(kind));
}

class _NoAnalytics implements AnalyticsService {
  @override
  void track(AnalyticsEvent event) {}
}

/// Registers a report model fed by [StubReportCases] (today: 21/10/2026).
Future<Widget> f1App(Widget page, {bool dark = false, double scale = 1}) async {
  await getIt.reset();
  final auth =
      DefaultAuthViewModel(
          DefaultAuthUseCases(
            AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
          ),
        )
        ..stage = AuthStage.unlocked
        ..hasPin = true
        ..ready = true;
  getIt.registerSingleton<AuthViewModel>(auth);
  getIt.registerSingleton<BudgetUseCases>(_NoBudget());
  getIt.registerSingleton<ReportViewModel>(
    DefaultReportViewModel(
      StubReportCases(),
      auth,
      _NoAnalytics(),
      FakeProfileViewModel(),
      clock: () => DateTime(2026, 10, 21),
    ),
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
      child: page,
    ),
  );
}

/// No monthly budget set: the report shows no budget row.
class _NoBudget implements BudgetUseCases {
  @override
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  }) async => right(
    const BudgetCurrent(
      budget: null,
      period: BudgetPeriod(
        from: '2026-10-01',
        to: '2026-10-31',
        timezone: 'Asia/Ho_Chi_Minh',
        fiscalMonthStartDay: 1,
      ),
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
