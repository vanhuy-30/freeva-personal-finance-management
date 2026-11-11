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

  /// Unit a new position of this kind starts with (gold may switch to
  /// `luong`).
  String get defaultUnit => switch (this) {
    gold => 'chi',
    stock => 'share',
    fund => 'unit',
    savingsDeposit => 'deposit',
    realEstate => 'property',
    crypto => 'coin',
  };

  /// Deposits and properties are one lot: quantity is fixed at 1 and the
  /// user types the total.
  bool get singleLot => this == savingsDeposit || this == realEstate;

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

/// What the editor sends to open a position with its first buy
/// (`POST /investments` with `initialTrade`).
class InvestmentDraft {
  const InvestmentDraft({
    required this.clientId,
    required this.tradeClientId,
    required this.kind,
    required this.name,
    required this.currencyCode,
    required this.unit,
    required this.quantity,
    required this.tradedOn,
    this.priceMinor,
    this.amountMinor,
    this.accountId,
    this.note,
    this.interestRateBps,
    this.startDate,
    this.maturityDate,
  });

  final String clientId;
  final String tradeClientId;
  final InvestmentKind kind;
  final String name;
  final String currencyCode;
  final String unit;

  /// Scaled by 10^8 (see `core/money/quantity.dart`).
  final BigInt quantity;
  final String tradedOn;

  /// Price of one unit; the server works out the total.
  final BigInt? priceMinor;

  /// Total paid (deposit principal, property price).
  final BigInt? amountMinor;

  /// Wallet the money comes from; null = already held before ("có sẵn").
  final String? accountId;
  final String? note;
  final int? interestRateBps;
  final String? startDate;
  final String? maturityDate;
}

enum TradeSide { buy, sell }

/// One buy or sell of a position (a "lần mua" or "lần bán").
class InvestmentTrade {
  const InvestmentTrade({
    required this.id,
    required this.clientId,
    required this.side,
    required this.quantity,
    required this.amountMinor,
    required this.unitPriceMinor,
    required this.tradedOn,
    this.realizedMinor,
    this.accountId,
    this.note,
    this.currentValueMinor,
    this.unrealizedMinor,
    this.unrealizedBps,
  });

  final String id;
  final String clientId;
  final TradeSide side;

  /// Scaled by 10^8.
  final BigInt quantity;
  final BigInt amountMinor;
  final BigInt unitPriceMinor;
  final String tradedOn;

  /// Sell only: proceeds minus the cost removed.
  final BigInt? realizedMinor;

  /// Null on a buy the user already held ("có sẵn").
  final String? accountId;
  final String? note;
  final BigInt? currentValueMinor;
  final BigInt? unrealizedMinor;
  final int? unrealizedBps;

  bool get existing => side == TradeSide.buy && accountId == null;
}

/// A sale of part or all of a position.
class SellDraft {
  const SellDraft({
    required this.clientId,
    required this.quantity,
    required this.accountId,
    required this.tradedOn,
    this.priceMinor,
    this.amountMinor,
  });

  final String clientId;

  /// Scaled by 10^8.
  final BigInt quantity;

  /// Price of one unit; it becomes the position's latest price.
  final BigInt? priceMinor;

  /// Total money back instead of a unit price (deposit withdrawal).
  final BigInt? amountMinor;
  final String accountId;
  final String tradedOn;
}

/// New values for a buy ("Sửa lần mua"); the wallet may become null
/// ("đã có từ trước", which removes the wallet leg).
class TradeEdit {
  const TradeEdit({
    required this.quantity,
    required this.accountId,
    required this.tradedOn,
    this.priceMinor,
    this.amountMinor,
    this.note,
  });

  /// Scaled by 10^8.
  final BigInt quantity;
  final String? accountId;
  final String tradedOn;

  /// Price of one unit; the server recomputes the total.
  final BigInt? priceMinor;

  /// Total, for one-lot kinds (property).
  final BigInt? amountMinor;
  final String? note;
}
