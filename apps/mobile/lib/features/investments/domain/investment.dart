/// The six kinds of asset the app tracks (ADR 014); `name` is the API value
/// except for the snake_case ones, see [apiValue].
enum InvestmentKind {
  gold('gold'),
  stock('stock'),
  fund('fund'),
  savingsDeposit('savings_deposit'),
  realEstate('real_estate'),
  crypto('crypto');

  const InvestmentKind(this.apiValue);

  final String apiValue;

  static InvestmentKind parse(String value) =>
      values.firstWhere((k) => k.apiValue == value);
}

/// How the value of a position is worked out.
enum InvestmentValuation {
  /// Latest manual price or trade price.
  price,

  /// Principal plus simple interest to maturity.
  deposit,

  /// No price yet: cost stands in and profit/loss is unknown.
  cost,
}

/// One position: an asset with a shared price and average cost.
class Investment {
  const Investment({
    required this.id,
    required this.clientId,
    required this.kind,
    required this.name,
    required this.currencyCode,
    required this.unit,
    required this.quantity,
    required this.costBasisMinor,
    required this.currentValueMinor,
    required this.valuation,
    required this.version,
    this.averageCostMinor,
    this.unrealizedMinor,
    this.unrealizedBps,
    this.latestPriceMinor,
    this.latestPriceAt,
    this.interestRateBps,
    this.startDate,
    this.maturityDate,
    this.note,
    this.archived = false,
  });

  final String id;
  final String clientId;
  final InvestmentKind kind;
  final String name;
  final String currencyCode;

  /// `chi`, `luong`, `share`, `unit`, `coin`, `deposit` or `property`.
  final String unit;

  /// Decimal text with up to 8 digits, kept as the API sent it.
  final String quantity;
  final BigInt costBasisMinor;
  final BigInt currentValueMinor;
  final InvestmentValuation valuation;
  final int version;
  final BigInt? averageCostMinor;

  /// Null while unpriced.
  final BigInt? unrealizedMinor;

  /// Signed basis points of cost, 1429 = 14,29%; null while unpriced.
  final int? unrealizedBps;
  final BigInt? latestPriceMinor;

  /// `quotedAt` of the latest price.
  final DateTime? latestPriceAt;
  final int? interestRateBps;
  final String? startDate;
  final String? maturityDate;
  final String? note;
  final bool archived;

  bool get unpriced => valuation == InvestmentValuation.cost;
}

/// Totals of one currency, whole or for one kind.
class InvestmentTotal {
  const InvestmentTotal({
    required this.currencyCode,
    required this.costBasisMinor,
    required this.currentValueMinor,
    required this.unrealizedMinor,
    required this.unpricedCount,
    this.unrealizedBps,
    this.kind,
    this.investmentCount = 0,
    this.shareBps,
  });

  final String currencyCode;
  final BigInt costBasisMinor;
  final BigInt currentValueMinor;
  final BigInt unrealizedMinor;

  /// Null when nothing is priced.
  final int? unrealizedBps;
  final int unpricedCount;

  /// Set on the per-kind rows only.
  final InvestmentKind? kind;
  final int investmentCount;

  /// Share of the currency's total value in basis points; per-kind rows only.
  final int? shareBps;
}

class InvestmentSummary {
  const InvestmentSummary({this.totals = const [], this.byKind = const []});

  final List<InvestmentTotal> totals;
  final List<InvestmentTotal> byKind;

  InvestmentTotal? totalOf(String currency) =>
      totals.where((t) => t.currencyCode == currency).firstOrNull;

  /// Kind rows of [currency], largest value first (the API order).
  List<InvestmentTotal> kindsOf(String currency) => [
    for (final row in byKind)
      if (row.currencyCode == currency) row,
  ];
}

/// Value of all held investments at one bucket of the history window.
class InvestmentValuePoint {
  const InvestmentValuePoint({required this.asOf, required this.valueMinor});

  final String asOf;
  final BigInt valueMinor;
}
