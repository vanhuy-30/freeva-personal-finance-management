/// Monthly spend limit and progress for one fiscal month (BE-P2-E02).
enum BudgetStatus { healthy, warning, critical, over }

/// Where limits are stored: template for every month, or one fiscal month only.
enum BudgetApplyTo { defaultTemplate, month }

class BudgetPeriod {
  const BudgetPeriod({
    required this.from,
    required this.to,
    required this.timezone,
    required this.fiscalMonthStartDay,
  });

  final String from;
  final String to;
  final String timezone;
  final int fiscalMonthStartDay;
}

class BudgetCategoryLine {
  const BudgetCategoryLine({
    required this.categoryId,
    required this.limitMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.percentBps,
    required this.status,
  });

  final String categoryId;
  final BigInt limitMinor;
  final BigInt spentMinor;
  final BigInt remainingMinor;
  final int percentBps;
  final BudgetStatus status;
}

class BudgetSummary {
  const BudgetSummary({
    required this.id,
    required this.currencyCode,
    required this.limitMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.percentBps,
    required this.status,
    required this.alertThresholds,
    required this.crossedThresholds,
    required this.categories,
    required this.period,
    required this.applyTo,
    required this.isOverride,
    required this.version,
  });

  final String id;
  final String currencyCode;
  final BigInt limitMinor;
  final BigInt spentMinor;
  final BigInt remainingMinor;
  final int percentBps;
  final BudgetStatus status;
  final List<int> alertThresholds;
  final List<int> crossedThresholds;
  final List<BudgetCategoryLine> categories;
  final BudgetPeriod period;
  final BudgetApplyTo applyTo;
  final bool isOverride;
  final int version;

  /// 0–1 of the limit for progress bars; over-budget clamps to 1.
  double get ratio {
    if (limitMinor <= BigInt.zero) return 0;
    final value = spentMinor * BigInt.from(10000) ~/ limitMinor;
    return (value.toInt() / 10000).clamp(0, 1).toDouble();
  }
}

class BudgetCurrent {
  const BudgetCurrent({required this.budget, required this.period});

  final BudgetSummary? budget;
  final BudgetPeriod period;
}

class BudgetCategoryDraft {
  const BudgetCategoryDraft({
    required this.categoryId,
    required this.limitMinor,
  });

  final String categoryId;
  final BigInt limitMinor;
}

class BudgetDraft {
  const BudgetDraft({
    required this.limitMinor,
    required this.alertThresholds,
    required this.categories,
    this.applyTo = BudgetApplyTo.defaultTemplate,
    this.on,
    this.version,
  });

  final BigInt limitMinor;
  final List<int> alertThresholds;
  final List<BudgetCategoryDraft> categories;
  final BudgetApplyTo applyTo;
  final String? on;
  final int? version;
}

const defaultAlertThresholds = [70, 80, 90, 100];

String budgetApplyToApi(BudgetApplyTo value) =>
    value == BudgetApplyTo.month ? 'month' : 'default';

BudgetApplyTo budgetApplyToFromApi(String value) =>
    value == 'month' ? BudgetApplyTo.month : BudgetApplyTo.defaultTemplate;
