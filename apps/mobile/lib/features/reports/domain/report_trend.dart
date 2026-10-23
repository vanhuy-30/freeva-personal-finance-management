import 'report.dart';

/// The bars for one currency and their average, for the trend card.
class TrendSeries {
  const TrendSeries({required this.bars, required this.average});

  final List<TrendBar> bars;

  /// Mean expense of all bars, rounded to a minor unit.
  final BigInt average;

  BigInt get peak =>
      bars.fold(BigInt.zero, (a, b) => a > b.expense ? a : b.expense);
}

class TrendBar {
  const TrendBar({
    required this.from,
    required this.to,
    required this.expense,
    required this.current,
  });

  final String from;
  final String to;
  final BigInt expense;

  /// The last bar is the period being viewed.
  final bool current;
}

TrendSeries trendSeries(TrendReport trend, String currency) {
  final last = trend.buckets.length - 1;
  final bars = [
    for (var i = 0; i < trend.buckets.length; i++)
      TrendBar(
        from: trend.buckets[i].from,
        to: trend.buckets[i].to,
        expense: trend.buckets[i].expenseOf(currency),
        current: i == last,
      ),
  ];
  final sum = bars.fold(BigInt.zero, (a, b) => a + b.expense);
  final count = BigInt.from(bars.isEmpty ? 1 : bars.length);
  return TrendSeries(
    bars: bars,
    average: (sum * BigInt.two + count) ~/ (count * BigInt.two),
  );
}
