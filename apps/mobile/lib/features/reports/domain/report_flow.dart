import 'report.dart';

/// How a period is cut for the cash flow chart: a day, a week or a month per point.
enum FlowGranularity { day, week, month }

/// Income and expense per bucket of one period, oldest first and never past
/// today (`GET /reports/flow`). Reuses [TrendBucket] for the per-currency totals.
class FlowReport {
  const FlowReport({
    required this.kind,
    required this.from,
    required this.to,
    required this.granularity,
    required this.buckets,
  });

  final ReportPeriodKind kind;
  final String from;
  final String to;
  final FlowGranularity granularity;
  final List<TrendBucket> buckets;
}

/// One point of the chart: what moved in the bucket and the running total.
class FlowPoint {
  const FlowPoint({
    required this.from,
    required this.to,
    required this.income,
    required this.expense,
    required this.cumulative,
  });

  final String from;
  final String to;

  /// Magnitudes; [net] is income minus expense.
  final BigInt income;
  final BigInt expense;

  /// Running net since the start of the period, including this point.
  final BigInt cumulative;

  BigInt get net => income - expense;
}

/// The cash flow chart's numbers for one currency.
class FlowSeries {
  const FlowSeries({
    required this.granularity,
    required this.points,
    required this.high,
    required this.low,
    required this.biggestIncome,
    required this.biggestExpense,
  });

  final FlowGranularity granularity;
  final List<FlowPoint> points;

  /// The axis always contains zero: [high] is never below 0 and [low] never above it.
  final BigInt high;
  final BigInt low;

  /// The bucket with the most income / expense; null when there was none.
  final FlowPoint? biggestIncome;
  final FlowPoint? biggestExpense;

  /// Nothing was earned or spent: the chart is replaced by an empty note.
  bool get isEmpty => biggestIncome == null && biggestExpense == null;

  BigInt get last => points.isEmpty ? BigInt.zero : points.last.cumulative;
}

/// Turns the buckets into a running total for [currency]. A bucket with no
/// activity in that currency still counts as a flat point so days stay evenly spaced.
FlowSeries flowSeries(FlowReport flow, String currency) {
  var running = BigInt.zero;
  var high = BigInt.zero;
  var low = BigInt.zero;
  FlowPoint? biggestIncome;
  FlowPoint? biggestExpense;
  final points = <FlowPoint>[];
  for (final bucket in flow.buckets) {
    var income = BigInt.zero;
    var expense = BigInt.zero;
    for (final total in bucket.totals) {
      if (total.currency != currency) continue;
      income += total.incomeMinor.abs();
      expense += total.expenseMinor.abs();
    }
    running += income - expense;
    if (running > high) high = running;
    if (running < low) low = running;
    final point = FlowPoint(
      from: bucket.from,
      to: bucket.to,
      income: income,
      expense: expense,
      cumulative: running,
    );
    points.add(point);
    if (income > BigInt.zero &&
        (biggestIncome == null || income > biggestIncome.income)) {
      biggestIncome = point;
    }
    if (expense > BigInt.zero &&
        (biggestExpense == null || expense > biggestExpense.expense)) {
      biggestExpense = point;
    }
  }
  return FlowSeries(
    granularity: flow.granularity,
    points: List.unmodifiable(points),
    high: high,
    low: low,
    biggestIncome: biggestIncome,
    biggestExpense: biggestExpense,
  );
}
