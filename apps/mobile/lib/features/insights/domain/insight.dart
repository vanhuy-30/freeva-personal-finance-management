/// Category named by an insight (top level; children are counted in it).
class InsightCategory {
  const InsightCategory({
    required this.id,
    required this.name,
    this.iconToken,
    this.colorToken,
  });

  final String id;
  final String name;
  final String? iconToken;
  final String? colorToken;
}

/// The fiscal month the insights were worked out for (`yyyy-MM-dd`).
class InsightPeriod {
  const InsightPeriod({
    required this.from,
    required this.to,
    required this.today,
  });

  final String from;
  final String to;
  final String today;
}

/// One rule-based finding about the running month (MOB-P5-E04, boards S.1,
/// S.2). The app builds the sentence from l10n templates per kind.
sealed class Insight {
  const Insight();
}

/// A budget (one category, or the whole month when [category] is null) is
/// [percent] used.
final class BudgetRiskInsight extends Insight {
  const BudgetRiskInsight({
    required this.category,
    required this.spentMinor,
    required this.limitMinor,
    required this.percent,
    required this.daysLeft,
  });

  final InsightCategory? category;
  final BigInt spentMinor;
  final BigInt limitMinor;
  final int percent;
  final int daysLeft;
}

/// One expense this month is [times] the usual one of its category.
final class OutlierInsight extends Insight {
  const OutlierInsight({
    required this.category,
    required this.transactionId,
    required this.merchant,
    required this.occurredOn,
    required this.amountMinor,
    required this.usualMinor,
    required this.times,
  });

  final InsightCategory category;
  final String transactionId;
  final String? merchant;
  final String occurredOn;
  final BigInt amountMinor;
  final BigInt usualMinor;
  final int times;
}

/// A category spent more ([up]) or less than the same days last month.
final class CategoryChangeInsight extends Insight {
  const CategoryChangeInsight({
    required this.category,
    required this.currentMinor,
    required this.previousMinor,
    required this.changePercent,
    required this.up,
  });

  final InsightCategory category;
  final BigInt currentMinor;
  final BigInt previousMinor;

  /// Null with too little history: the sentence says it without a number.
  final int? changePercent;
  final bool up;
}

/// All spending of the first [days] days against the same days last month.
final class SpendTrendInsight extends Insight {
  const SpendTrendInsight({
    required this.currentMinor,
    required this.previousMinor,
    required this.changePercent,
    required this.up,
    required this.days,
  });

  final BigInt currentMinor;
  final BigInt previousMinor;

  /// Null with too little history: the sentence says it without a number.
  final int? changePercent;
  final bool up;
  final int days;
}

/// `GET /insights`: at most one item per kind, in the server's priority order.
class InsightList {
  const InsightList({
    required this.currencyCode,
    required this.period,
    required this.items,
  });

  static const empty = InsightList(currencyCode: null, period: null, items: []);

  /// Profile currency; every amount is in it.
  final String? currencyCode;
  final InsightPeriod? period;
  final List<Insight> items;
}
