import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/domain/budget_use_cases.dart';
import '../../calendar/domain/calendar_month.dart';
import '../../calendar/domain/calendar_use_cases.dart';
import '../../investments/domain/investment_use_cases.dart';
import '../../loans/domain/loan_use_cases.dart';
import '../../net_worth/domain/net_worth_history.dart';
import '../../net_worth/domain/net_worth_use_cases.dart';
import '../../categories/domain/category_repository.dart';
import '../../../core/money/currency_usage.dart';
import '../../fx_rates/domain/fx_rate_repository.dart';
import '../../reports/domain/report.dart';
import '../../reports/domain/report_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_money.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../wallets/domain/wallet_repository.dart';
import 'overview.dart';
import 'overview_glance.dart';
import '../../server_config/domain/app_limits.dart';

abstract class OverviewUseCases {
  /// Loads balances, this month, wallets, the 3 latest transactions and
  /// categories. Adds last month only when this month is still empty.
  /// [displayCurrency] also asks the server for converted totals. The
  /// glance tiles (net worth trend, investments, loans, calendar) are best
  /// effort; [currency] is the profile currency of the net worth trend.
  Future<Either<AuthFailure, OverviewData>> load(
    DateTime now, {
    String? displayCurrency,
    String? currency,
  });

  /// Saves a rate the user typed (1 [from] = [rate] [to]). Null when [rate]
  /// is not a positive decimal; nothing is sent then.
  Future<Either<AuthFailure, Unit>>? saveRate(
    String from,
    String to,
    String rate,
  );
}

@LazySingleton(as: OverviewUseCases)
class DefaultOverviewUseCases implements OverviewUseCases {
  DefaultOverviewUseCases(
    this._reports,
    this._wallets,
    this._transactions,
    this._categories,
    this._budgets,
    this._rates,
    this._limits,
    this._netWorth,
    this._investments,
    this._loans,
    this._calendar,
  );

  final AppLimitsSource _limits;

  final ReportRepository _reports;
  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetUseCases _budgets;
  final FxRateRepository _rates;
  final NetWorthUseCases _netWorth;
  final InvestmentUseCases _investments;
  final LoanUseCases _loans;
  final CalendarUseCases _calendar;

  /// Recent transactions on Home (server `home.recentTransactions`).
  int get recentCount => _limits.requireLimits.homeRecentTransactions;

  @override
  Future<Either<AuthFailure, OverviewData>> load(
    DateTime now, {
    String? displayCurrency,
    String? currency,
  }) async {
    // Start every request first so they run in parallel, then read in order.
    final worthF = _reports.netWorth(displayCurrency: displayCurrency);
    final monthF = _reports.cashflow(
      const ReportPeriodQuery.month(),
      displayCurrency: displayCurrency,
    );
    final walletsF = _wallets.load();
    final currenciesF = _wallets.currencies();
    // A transfer is two legs, so ask for twice as many.
    final recentF = _transactions.list(
      TransactionQuery(pageSize: recentCount * 2),
    );
    final categoriesF = _categories.load();
    final budgetF = _budgets.current();
    final trendCurrency = currency ?? displayCurrency;
    final trendF = trendCurrency == null
        ? null
        : _netWorth.load(NetWorthWindow.month, currency: trendCurrency);
    final investmentsF = _investments.summary();
    final loansF = _loans.list();
    try {
      final worth = _take(await worthF);
      final month = _take(await monthF);
      final calendarF = _calendarUntil(now, month.period.to);
      final wallets = _take(await walletsF);
      final currencies = _take(await currenciesF);
      final page = _take(await recentF);
      final categories = _take(await categoriesF);
      // Budget is optional on Home: a failure just hides the progress bar.
      final BudgetSummary? budget = (await budgetF).fold(
        (_) => null,
        (current) => current.budget,
      );
      final previous = await _previousIfEmpty(month);
      final older = previous == null ? null : await _olderThan(previous);
      final calendar = await calendarF;
      return right(
        OverviewData(
          netWorth: worth,
          month: month,
          previousMonth: previous,
          monthBefore: older?.$1,
          previousBudget: older?.$2,
          budget: budget,
          netWorthTrend: trendF == null ? null : _optional(await trendF),
          investments: _optional(await investmentsF),
          loans: _optional(await loansF),
          calendar: calendar,
          multiCurrency: usesMultipleCurrencies([
            for (final w in wallets) w.draft.currency,
            for (final row in worth.items) row.currency,
            for (final row in month.totals) row.currency,
          ]),
          wallets: [
            for (final w in wallets)
              if (!w.archived) w,
          ],
          currencies: currencies,
          recent: groupTransactionLegs(page.legs).take(recentCount).toList(),
          categories: categories.all,
          loadedAt: now,
        ),
      );
    } on _Failed catch (failed) {
      return left(failed.failure);
    }
  }

  @override
  Future<Either<AuthFailure, Unit>>? saveRate(
    String from,
    String to,
    String rate,
  ) {
    final normalized = normalizeRate(rate);
    if (normalized == null || from == to) return null;
    return _rates.put(from, to, normalized).then((r) => r.map((_) => unit));
  }

  /// Calendar months from [now] to [to] (the fiscal month end), for bills
  /// and recurring items. Null when any month failed.
  Future<List<CalendarMonth>?> _calendarUntil(DateTime now, String to) async {
    final until = DateTime.tryParse(to);
    if (until == null) return null;
    final months = await Future.wait([
      for (final key in calendarMonthsBetween(now, until)) _calendar.month(key),
    ]);
    final loaded = <CalendarMonth>[];
    for (final month in months) {
      final value = _optional(month);
      if (value == null) return null;
      loaded.add(value);
    }
    return loaded;
  }

  /// Last month, only while this month has no income or expense. Best
  /// effort: the review card is optional, so a failure just hides it.
  Future<CashflowReport?> _previousIfEmpty(CashflowReport month) async {
    final empty = month.totals.every(
      (t) => t.incomeMinor == BigInt.zero && t.expenseMinor == BigInt.zero,
    );
    if (!empty) return null;
    final before = DateTime.parse(month.period.from)
        .subtract(const Duration(days: 1));
    final result = await _reports.cashflow(
      ReportPeriodQuery.month(on: _date(before)),
    );
    return result.fold((_) => null, (report) => report);
  }

  /// The month before [previous] and [previous]'s budget, for the review
  /// card's two extra lines. Best effort: each is null when it fails.
  Future<(CashflowReport?, BudgetSummary?)> _olderThan(
    CashflowReport previous,
  ) async {
    final before = DateTime.parse(previous.period.from)
        .subtract(const Duration(days: 1));
    final reportF = _reports.cashflow(
      ReportPeriodQuery.month(on: _date(before)),
    );
    final budgetF = _budgets.current(on: previous.period.from);
    final report = (await reportF).fold((_) => null, (r) => r);
    final budget = (await budgetF).fold((_) => null, (b) => b.budget);
    return (report, budget);
  }
}

class _Failed implements Exception {
  const _Failed(this.failure);
  final AuthFailure failure;
}

T? _optional<T>(Either<AuthFailure, T> result) =>
    result.fold((_) => null, (value) => value);

T _take<T>(Either<AuthFailure, T> result) =>
    result.fold((failure) => throw _Failed(failure), (value) => value);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
