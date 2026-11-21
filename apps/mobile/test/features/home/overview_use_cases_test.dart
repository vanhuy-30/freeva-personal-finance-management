import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/domain/budget_use_cases.dart';
import 'package:mobile/features/categories/domain/category_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_month.dart';
import 'package:mobile/features/calendar/domain/calendar_use_cases.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/loans/domain/loan.dart';
import 'package:mobile/features/loans/domain/loan_use_cases.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/net_worth/domain/net_worth_use_cases.dart';
import 'package:mobile/features/home/domain/overview_use_cases.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_flow.dart';
import 'package:mobile/features/reports/domain/report_holdings.dart';
import 'package:mobile/features/reports/domain/report_repository.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_repository.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

import '../fx_rates/fakes.dart';
import 'fixtures.dart';

void main() {
  late _Reports reports;
  late _Transactions transactions;
  late DefaultOverviewUseCases cases;
  late MemoryFxRates rates;
  late _Budgets budgets;
  late _Glance glance;

  setUp(() {
    glance = _Glance();
    reports = _Reports();
    rates = MemoryFxRates();
    budgets = _Budgets();
    transactions = _Transactions();
    cases = DefaultOverviewUseCases(
      reports,
      _Wallets(),
      transactions,
      _Categories(),
      budgets,
      rates,
      testServerConfigModel(),
      glance.netWorth,
      glance.investments,
      glance.loans,
      glance.calendar,
    );
  });

  test('loads the glance data best effort (PA 3)', () async {
    reports.months = [month()];
    final data = (await cases.load(
      DateTime(2026, 10, 21),
      currency: 'VND',
    )).getOrElse(() => throw StateError('load'));
    expect(glance.trendCurrency, 'VND');
    expect(glance.months, ['2026-10']);
    expect(data.netWorthTrend?.currency, 'VND');
    expect(data.investments, isNotNull);
    expect(data.loans, isEmpty);
    expect(data.calendar, hasLength(1));

    glance.fail = true;
    final partial = (await cases.load(
      DateTime(2026, 10, 21),
      currency: 'VND',
    )).getOrElse(() => throw StateError('load'));
    expect(partial.netWorthTrend, isNull);
    expect(partial.investments, isNull);
    expect(partial.loans, isNull);
    expect(partial.calendar, isNull);
    expect(partial.wallets, isNotEmpty);
  });

  test(
    'saves a typed rate with 8 decimals and sends nothing when invalid',
    () async {
      final saved = await cases.saveRate('USD', 'VND', ' 25000.5 ')!;
      expect(saved.isRight(), isTrue);
      expect(rates.saved, ['USD>VND=25000.50000000']);
      for (final bad in ['', '0', '-1', 'abc', '1e3', '1.123456789']) {
        expect(cases.saveRate('USD', 'VND', bad), isNull, reason: bad);
      }
      expect(cases.saveRate('USD', 'USD', '1'), isNull);
      expect(rates.saved, hasLength(1));
    },
  );

  test('loads the current month only, hides archived wallets', () async {
    reports.months = [month()];
    final data = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(reports.queries.single.on, isNull);
    expect(data.previousMonth, isNull);
    expect(data.wallets.map((w) => w.id), ['vcb']);
    expect(transactions.query?.pageSize, 6);
  });

  test('multiCurrency counts archived wallets and month totals', () async {
    reports.months = [month()];
    final one = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(one.multiCurrency, isFalse);

    reports.months = [
      month(extra: [usdSpend()]),
    ];
    final two = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(two.multiCurrency, isTrue);
  });

  test('a transfer counts as one recent row', () async {
    reports.months = [month()];
    transactions.legs = [
      leg(
        'a',
        account: 'vcb',
        amount: -500,
        type: TransactionType.transfer,
        group: 'g',
      ),
      leg(
        'b',
        account: 'momo',
        amount: 500,
        type: TransactionType.transfer,
        group: 'g',
      ),
      leg('c', account: 'vcb', amount: -1),
      leg('d', account: 'vcb', amount: -2),
      leg('e', account: 'vcb', amount: -3),
    ];
    final data = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(data.recent, hasLength(3));
    expect(data.recent.first.legs, hasLength(2));
  });

  test('an empty month also loads the previous month', () async {
    reports.months = [
      month(
        income: 0,
        expense: 0,
        rows: const [],
        from: '2026-11-01',
        to: '2026-11-30',
      ),
      month(),
    ];
    final data = (await cases.load(DateTime(2026, 11, 2)))
        .getOrElse(() => throw StateError('load'));
    expect(reports.queries[1].on, '2026-10-31');
    expect(reports.queries.last.on, '2026-09-30');
    expect(data.previousMonth, isNotNull);
    expect(data.monthBefore, isNotNull);
    expect(data.previousBudget?.spentMinor, b(15600000));
    expect(budgets.asked, [null, '2026-10-01']);
  });

  test('a failing older month or budget does not fail the load', () async {
    reports.months = [
      month(income: 0, expense: 0, rows: const [], from: '2026-11-01'),
      month(),
    ];
    reports.failAfter = 2;
    budgets.fail = true;
    final data = (await cases.load(DateTime(2026, 11, 2)))
        .getOrElse(() => throw StateError('load'));
    expect(data.previousMonth, isNotNull);
    expect(data.monthBefore, isNull);
    expect(data.previousBudget, isNull);
  });

  test('any required request failing fails the load', () async {
    reports.months = [month()];
    reports.worthFailure = const AuthFailure(AuthError.network);
    final result = await cases.load(DateTime(2026, 10, 21));
    expect(result.isLeft(), isTrue);
  });
}

class _Reports implements ReportRepository {
  List<CashflowReport> months = [];
  final queries = <ReportPeriodQuery>[];
  AuthFailure? worthFailure;

  /// Calls after this many answer with a failure.
  int? failAfter;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query, {
    String? displayCurrency,
  }) async {
    queries.add(query);
    if (failAfter != null && queries.length > failAfter!) {
      return left(const AuthFailure(AuthError.network));
    }
    return right(months.length > 1 ? months.removeAt(0) : months.single);
  }

  @override
  Future<Either<AuthFailure, MonthReviewReport>> monthReview({
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, FlowReport>> flow(ReportPeriodQuery query) async =>
      left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, HoldingsReport>> holdings(
    ReportPeriodQuery query,
  ) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth({
    String? displayCurrency,
  }) async => worthFailure != null
      ? left(worthFailure!)
      : right(NetWorthReport(items: [worth('VND', 100)]));
}

class _Wallets implements WalletRepository {
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right([
    wallet('vcb', 'Vietcombank'),
    wallet('old', 'Cũ', archived: true),
  ]);

  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      right(const [WalletCurrency('VND', 0)]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionRepository {
  TransactionQuery? query;
  List<TxLeg> legs = [];

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async {
    this.query = query;
    return right(TransactionListPage(legs: legs, page: 1, total: legs.length));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() async =>
      right(const CategoryCatalog(all: categories, recent: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Budgets implements BudgetUseCases {
  final asked = <String?>[];
  bool fail = false;

  @override
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  }) async {
    asked.add(on);
    if (fail) return left(const AuthFailure(AuthError.network));
    return right(_current(on));
  }

  BudgetCurrent _current(String? on) => BudgetCurrent(
    budget: on == null ? null : budgetOf(15000000, 15600000),
    period: const BudgetPeriod(
      from: '2026-10-01',
      to: '2026-10-31',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalMonthStartDay: 1,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Net worth trend, investments, loans and calendar for the PA 3 tiles.
class _Glance {
  bool fail = false;
  String? trendCurrency;
  final months = <String>[];
  late final netWorth = _NetWorth(this);
  late final investments = _Investments(this);
  late final loans = _Loans(this);
  late final calendar = _Calendar(this);

  Either<AuthFailure, T> result<T>(T value) =>
      fail ? left(const AuthFailure(AuthError.network)) : right(value);
}

class _NetWorth implements NetWorthUseCases {
  _NetWorth(this.glance);
  final _Glance glance;

  @override
  Future<Either<AuthFailure, NetWorthSeries>> load(
    NetWorthWindow window, {
    required String currency,
  }) async {
    glance.trendCurrency = currency;
    return glance.result(
      NetWorthSeries(window: window, currency: currency, points: const []),
    );
  }
}

class _Investments implements InvestmentUseCases {
  _Investments(this.glance);
  final _Glance glance;

  @override
  Future<Either<AuthFailure, InvestmentSummary>> summary() async =>
      glance.result(const InvestmentSummary());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Loans implements LoanUseCases {
  _Loans(this.glance);
  final _Glance glance;

  @override
  Future<Either<AuthFailure, List<Loan>>> list() async =>
      glance.result(const <Loan>[]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Calendar implements CalendarUseCases {
  _Calendar(this.glance);
  final _Glance glance;

  @override
  Future<Either<AuthFailure, CalendarMonth>> month(String month) async {
    glance.months.add(month);
    return glance.result(
      CalendarMonth(month: month, timezone: 'UTC', today: '', days: const []),
    );
  }
}
