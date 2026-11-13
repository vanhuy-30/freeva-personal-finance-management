/// When a goal is likely to be reached at the recent pace (MOB-P5-E06, board
/// T.1). Worked out on the server from the last completed months.
sealed class GoalForecast {
  const GoalForecast();
}

/// Already saved in full: no card.
final class GoalForecastReached extends GoalForecast {
  const GoalForecastReached();
}

/// Nothing (or less than nothing) put in over the last [months] months.
final class GoalForecastInsufficient extends GoalForecast {
  const GoalForecastInsufficient({required this.months});

  final int months;
}

final class GoalForecastOk extends GoalForecast {
  const GoalForecastOk({
    required this.months,
    required this.averageMonthlyMinor,
    required this.expectedMonth,
    required this.targetMonth,
    required this.monthsLate,
  });

  /// Completed months the average is taken over.
  final int months;

  /// Net contribution per month, in the goal's currency.
  final BigInt averageMonthlyMinor;

  /// `yyyy-MM`.
  final String expectedMonth;

  /// `yyyy-MM`; null without a target date.
  final String? targetMonth;

  /// Positive late, negative early, 0 on time; null without a target date.
  final int? monthsLate;
}
