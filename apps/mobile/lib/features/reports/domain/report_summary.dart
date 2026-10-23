import 'report.dart';
import 'report_period.dart';

/// Figures of the totals card for one currency. Amounts are magnitudes except
/// [remaining], which is income minus expense and may be negative.
class ReportSummary {
  const ReportSummary({
    required this.income,
    required this.expense,
    required this.remaining,
    required this.averagePerDay,
    required this.expenseChange,
  });

  final BigInt income;
  final BigInt expense;
  final BigInt remaining;

  /// Null when the period has not started.
  final BigInt? averagePerDay;

  /// Whole-percent change of expense against the previous period; null when
  /// the previous period is unknown or had no expense.
  final int? expenseChange;
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
  final before = previous == null ? null : _totalOf(previous, currency);
  return ReportSummary(
    income: income,
    expense: expense,
    remaining: income - expense,
    averagePerDay: averagePerDay(expense, report.period, today),
    expenseChange: before == null
        ? null
        : expenseChange(expense, before.expenseMinor.abs()),
  );
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

/// (current − previous) ÷ previous, rounded half away from zero.
int? expenseChange(BigInt current, BigInt previous) {
  if (previous == BigInt.zero) return null;
  final delta = (current - previous) * BigInt.from(100);
  final twice = delta * BigInt.two ~/ previous;
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
