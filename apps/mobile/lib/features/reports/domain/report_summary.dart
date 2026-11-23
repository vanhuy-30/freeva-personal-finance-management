import 'report.dart';
import 'report_period.dart';

/// Figures of the totals card for one currency. Amounts are magnitudes except
/// [savings], which is income minus expense and may be negative. Every
/// `*Change` is against the period before and is null for a custom range, when
/// that period is unknown, or when there is nothing to compare with.
class ReportSummary {
  const ReportSummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.averagePerDay,
    this.savingsRateBps,
    this.walletBalance,
    this.incomeChangeBps,
    this.expenseChangeBps,
    this.savingsChangeBps,
    this.savingsRateChangeBps,
    this.averageChangeBps,
    this.walletChangeBps,
  });

  final BigInt income;
  final BigInt expense;

  /// Income minus expense.
  final BigInt savings;

  /// Null when the period has not started.
  final BigInt? averagePerDay;

  /// Basis points of income that was saved; null when there was no income.
  final int? savingsRateBps;

  /// Money in the non-credit wallets at the end of the period (today while it
  /// runs); null when the server did not send it.
  final BigInt? walletBalance;

  final int? incomeChangeBps;
  final int? expenseChangeBps;
  final int? savingsChangeBps;

  /// Difference of the savings rate in basis points (5 points = 500).
  final int? savingsRateChangeBps;
  final int? averageChangeBps;
  final int? walletChangeBps;

  /// Income minus expense, kept for callers that read it as "còn lại".
  BigInt get remaining => savings;
}

ReportSummary reportSummary(
  CashflowReport report,
  String currency,
  String today, {
  CashflowReport? previous,
}) {
  final row = _totalOf(report, currency);
  final income = row?.incomeMinor.abs() ?? BigInt.zero;
  final expense = row?.expenseMinor.abs() ?? BigInt.zero;
  final savings = income - expense;
  final average = averagePerDay(expense, report.period, today);
  final rate = savingsRateBps(savings, income);
  final balance = report.walletBalances
      .where((item) => item.currency == currency)
      .firstOrNull;
  // A custom range has no "previous" worth comparing with.
  final compare = report.period.kind == ReportPeriodKind.range
      ? null
      : previous;
  final before = compare == null ? null : _totalOf(compare, currency);
  final beforeIncome = before?.incomeMinor.abs();
  final beforeExpense = before?.expenseMinor.abs();
  final beforeSavings = (beforeIncome == null || beforeExpense == null)
      ? null
      : beforeIncome - beforeExpense;
  final beforeRate = beforeSavings == null || beforeIncome == null
      ? null
      : savingsRateBps(beforeSavings, beforeIncome);
  final previousLength = compare == null ? null : periodLength(compare.period);
  final beforeAverage = beforeExpense == null || previousLength == null
      ? null
      : _roundedDiv(beforeExpense, previousLength);
  return ReportSummary(
    income: income,
    expense: expense,
    savings: savings,
    averagePerDay: average,
    savingsRateBps: rate,
    walletBalance: balance?.endMinor,
    incomeChangeBps: beforeIncome == null
        ? null
        : changeBps(income, beforeIncome),
    expenseChangeBps: beforeExpense == null
        ? null
        : changeBps(expense, beforeExpense),
    savingsChangeBps: beforeSavings == null
        ? null
        : changeBps(savings, beforeSavings),
    savingsRateChangeBps: rate == null || beforeRate == null
        ? null
        : rate - beforeRate,
    averageChangeBps: average == null || beforeAverage == null
        ? null
        : changeBps(average, beforeAverage),
    walletChangeBps:
        compare == null ||
            balance == null ||
            balance.previousEndMinor <= BigInt.zero
        ? null
        : changeBps(balance.endMinor, balance.previousEndMinor),
  );
}

/// Basis points of [income] that [savings] is (2540 = 25,4%); null without income.
int? savingsRateBps(BigInt savings, BigInt income) {
  if (income <= BigInt.zero) return null;
  final twice = savings * BigInt.from(20000) ~/ income;
  final rounded = twice.isNegative
      ? (twice - BigInt.one) ~/ BigInt.two
      : (twice + BigInt.one) ~/ BigInt.two;
  return rounded.toInt();
}

BigInt _roundedDiv(BigInt value, int divisor) {
  final twice = value * BigInt.two ~/ BigInt.from(divisor);
  return (twice + BigInt.one) ~/ BigInt.two;
}

/// Expense over the days that have passed (running period) or the whole
/// period (finished one). Rounded to the nearest minor unit.
BigInt? averagePerDay(BigInt expense, ReportPeriod period, String today) {
  final length = daysApart(period.from, period.to);
  final elapsed = daysApart(period.from, today);
  if (length == null || elapsed == null || elapsed < 0) return null;
  final days = elapsed > length ? length + 1 : elapsed + 1;
  final twice = expense * BigInt.two ~/ BigInt.from(days);
  return (twice + BigInt.one) ~/ BigInt.two;
}

/// (current − previous) ÷ |previous| in basis points (1234 = 12,34%), rounded
/// half away from zero; null when previous is zero.
int? changeBps(BigInt current, BigInt previous) {
  if (previous == BigInt.zero) return null;
  final delta = (current - previous) * BigInt.from(10000);
  final twice = delta * BigInt.two ~/ previous.abs();
  final rounded = twice.isNegative
      ? (twice - BigInt.one) ~/ BigInt.two
      : (twice + BigInt.one) ~/ BigInt.two;
  return rounded.toInt();
}

/// Currencies that have activity in [report], sorted by code.
List<String> reportCurrencies(CashflowReport report) => {
  ...report.totals.map((row) => row.currency),
  ...report.byAccount.map((row) => row.currency),
}.toList()..sort();

/// The currency to show: the user's [chosen] one while it still has data,
/// else [preferred] (profile currency), else the first.
String? pickCurrency(List<String> available, String? chosen, String preferred) {
  if (available.isEmpty) return null;
  if (chosen != null && available.contains(chosen)) return chosen;
  return available.contains(preferred) ? preferred : available.first;
}

CashflowTotal? _totalOf(CashflowReport report, String currency) =>
    report.totals.where((row) => row.currency == currency).firstOrNull;
