/// A rate the user typed: 1 [from] = [rate] [to] at [quotedAt]. Used only to
/// show converted amounts.
class FxRate {
  const FxRate({
    required this.from,
    required this.to,
    required this.rate,
    required this.quotedAt,
  });

  final String from;
  final String to;

  /// Decimal text with 8 fractional digits.
  final String rate;
  final DateTime quotedAt;
}
