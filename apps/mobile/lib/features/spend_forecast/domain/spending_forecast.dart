/// How the month's projected spending sits against the whole-month budget.
enum SpendRisk { low, medium, high }

/// Whether there were enough days to project the month.
enum SpendForecastStatus { ok, insufficient }

/// The fiscal month the forecast is for (`yyyy-MM-dd`).
class SpendForecastPeriod {
  const SpendForecastPeriod({
    required this.from,
    required this.to,
    required this.today,
  });

  final String from;
  final String to;
  final String today;
}

/// Spent so far up to and including [date].
class SpendPoint {
  const SpendPoint({required this.date, required this.spentMinor});

  final String date;
  final BigInt spentMinor;
}

/// Top-level category the month went to most; children are counted in it.
class SpendTopCategory {
  const SpendTopCategory({
    required this.id,
    required this.name,
    required this.iconToken,
    required this.colorToken,
    required this.spentMinor,
    required this.sharePercent,
  });

  final String id;
  final String name;
  final String? iconToken;
  final String? colorToken;
  final BigInt spentMinor;

  /// Share of the month's spending, 0..100.
  final int sharePercent;
}

/// Month-end spending projected from the daily average so far (MOB-P5-E06,
/// boards S.2, S.3). A prediction, never recorded spending.
class SpendingForecast {
  const SpendingForecast({
    required this.status,
    required this.daysElapsed,
    required this.daysInPeriod,
    required this.spentMinor,
    required this.forecastMinor,
    required this.dailyAverageMinor,
    required this.budgetLimitMinor,
    required this.risk,
    required this.overBudgetMinor,
    required this.dailyAllowanceMinor,
    required this.previousMonthMinor,
    required this.cumulative,
    required this.topCategories,
  });

  final SpendForecastStatus status;
  final int daysElapsed;
  final int daysInPeriod;
  final BigInt spentMinor;

  /// Null while [status] is insufficient.
  final BigInt? forecastMinor;
  final BigInt dailyAverageMinor;

  /// Whole-month budget in the profile currency; null without one.
  final BigInt? budgetLimitMinor;

  /// Null without a budget.
  final SpendRisk? risk;

  /// Forecast minus budget, only when above it.
  final BigInt? overBudgetMinor;

  /// What can still be spent each day to stay inside the budget; null
  /// without a budget, once over it, or on the last day.
  final BigInt? dailyAllowanceMinor;

  /// The whole previous month: the comparison without a budget.
  final BigInt previousMonthMinor;

  /// One point per elapsed day.
  final List<SpendPoint> cumulative;
  final List<SpendTopCategory> topCategories;

  bool get ready => status == SpendForecastStatus.ok && forecastMinor != null;
}

/// `GET /spending-forecast`. [forecast] is null when forecasts are off.
class SpendingForecastResult {
  const SpendingForecastResult({
    required this.currencyCode,
    required this.period,
    required this.forecast,
  });

  static const none = SpendingForecastResult(
    currencyCode: null,
    period: null,
    forecast: null,
  );

  /// Profile currency; every amount is in it.
  final String? currencyCode;
  final SpendForecastPeriod? period;
  final SpendingForecast? forecast;
}
