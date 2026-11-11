/// Windows the history endpoint accepts; `value` is the query string.
enum NetWorthWindow {
  week('7d'),
  month('30d'),
  quarter('3m'),
  half('6m'),
  year('1y'),
  all('all');

  const NetWorthWindow(this.value);

  final String value;

  /// Window for a server code (`netWorth.defaultWindow`…). A code this build
  /// does not know (server newer than the app) shows everything.
  static NetWorthWindow fromValue(String value) => NetWorthWindow.values
      .firstWhere((window) => window.value == value, orElse: () => all);
}

/// One bucket of the history in a single currency, valued on [asOf].
class NetWorthPoint {
  const NetWorthPoint({
    required this.asOf,
    required this.assetsMinor,
    required this.liabilitiesMinor,
    required this.netWorthMinor,
    this.investmentMinor,
  });

  /// `YYYY-MM-DD`.
  final String asOf;
  final BigInt assetsMinor;

  /// Signed: negative means debt.
  final BigInt liabilitiesMinor;
  final BigInt netWorthMinor;

  /// Held investments on [asOf]; null when that history could not be read.
  final BigInt? investmentMinor;

  /// Assets outside investments (wallets and money owed to the user).
  BigInt? get walletMinor =>
      investmentMinor == null ? null : assetsMinor - investmentMinor!;
}

/// Oldest-first points of the default currency.
class NetWorthSeries {
  const NetWorthSeries({
    required this.window,
    required this.currency,
    required this.points,
  });

  final NetWorthWindow window;
  final String currency;
  final List<NetWorthPoint> points;

  NetWorthPoint? get latest => points.isEmpty ? null : points.last;

  /// Change from the first point to the last; null with fewer than two.
  BigInt? get changeMinor => points.length < 2
      ? null
      : points.last.netWorthMinor - points.first.netWorthMinor;

  /// A line needs two points.
  bool get hasChart => points.length >= 2;
}
