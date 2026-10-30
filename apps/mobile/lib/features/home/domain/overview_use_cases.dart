import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../budgets/domain/budget.dart';
import '../../budgets/domain/budget_use_cases.dart';
import '../../categories/domain/category_repository.dart';
import '../../fx_rates/domain/fx_rate_repository.dart';
import '../../reports/domain/report.dart';
import '../../reports/domain/report_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../../transactions/domain/transaction_money.dart';
import '../../transactions/domain/transaction_repository.dart';
import '../../wallets/domain/wallet_repository.dart';
import 'overview.dart';

abstract class OverviewUseCases {
  /// Loads balances, this month, wallets, the 3 latest transactions and
  /// categories. Adds last month only when this month is still empty.
  /// [displayCurrency] also asks the server for converted totals.
  Future<Either<AuthFailure, OverviewData>> load(
    DateTime now, {
    String? displayCurrency,
  });

  /// Saves a rate the user typed (1 [from] = [rate] [to]). Null when [rate]
  /// is not a positive decimal; nothing is sent then.
  Future<Either<AuthFailure, Unit>>? saveRate(String from, String to, String rate);
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
  );

  final ReportRepository _reports;
  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetUseCases _budgets;
  final FxRateRepository _rates;

  static const recentCount = 3;

  @override
  Future<Either<AuthFailure, OverviewData>> load(
    DateTime now, {
    String? displayCurrency,
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
      const TransactionQuery(pageSize: recentCount * 2),
    );
    final categoriesF = _categories.load();
    final budgetF = _budgets.current();
    try {
      final worth = _take(await worthF);
      final month = _take(await monthF);
      final wallets = _take(await walletsF);
      final currencies = _take(await currenciesF);
      final page = _take(await recentF);
      final categories = _take(await categoriesF);
      // Budget is optional on Home: a failure just hides the progress bar.
      final BudgetSummary? budget = (await budgetF).fold(
        (_) => null,
        (current) => current.budget,
      );
      return right(
        OverviewData(
          netWorth: worth,
          month: month,
          previousMonth: await _previousIfEmpty(month),
          budget: budget,
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
}

class _Failed implements Exception {
  const _Failed(this.failure);
  final AuthFailure failure;
}

T _take<T>(Either<AuthFailure, T> result) =>
    result.fold((failure) => throw _Failed(failure), (value) => value);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
