import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/spending_forecast.dart';

/// Tone of a forecast chip or tile; the widget maps it to status tokens.
enum ForecastTone { success, warning, danger, neutral }

/// Risk chip text and tone; null without a budget (no chip).
(String, ForecastTone)? riskChip(S s, SpendRisk? risk) => switch (risk) {
  SpendRisk.low => (s.spendForecastRiskLow, ForecastTone.success),
  SpendRisk.medium => (s.spendForecastRiskMedium, ForecastTone.warning),
  SpendRisk.high => (s.spendForecastRiskHigh, ForecastTone.danger),
  null => null,
};

/// Month number or name of the fiscal month ("11", "November").
String forecastMonth(S s, String locale, SpendForecastPeriod? period) =>
    period == null
    ? ''
    : DateFormat(
        s.homeMonthPattern,
        locale,
      ).format(DateTime.parse(period.from));

/// Right side of the S.2 legend: the budget, or last month without one.
String forecastCompare(S s, SpendingForecast f, String Function(BigInt) money) {
  final budget = f.budgetLimitMinor;
  return budget == null
      ? s.spendForecastPrevious(money(f.previousMonthMinor))
      : s.spendForecastBudget(money(budget));
}

/// Second S.3 tile: what each day may still take to stay inside the budget,
/// or last month when there is no such figure (no budget, already over, or
/// the last day).
(String label, String value, ForecastTone tone) forecastSideTile(
  S s,
  SpendingForecast f,
  String Function(BigInt) money,
) {
  final allowance = f.dailyAllowanceMinor;
  if (allowance == null) {
    return (
      s.spendForecastLastMonth,
      money(f.previousMonthMinor),
      ForecastTone.neutral,
    );
  }
  return (
    s.spendForecastAllowance,
    s.spendForecastAllowanceValue(money(allowance)),
    ForecastTone.success,
  );
}

/// What the S.3 chart says to a screen reader.
String forecastChartLabel(
  S s,
  SpendingForecast f,
  String Function(BigInt) money,
) {
  final forecast = money(f.forecastMinor ?? BigInt.zero);
  final budget = f.budgetLimitMinor;
  return budget == null
      ? s.spendForecastChart(f.daysElapsed, money(f.spentMinor), forecast)
      : s.spendForecastChartBudget(
          f.daysElapsed,
          money(f.spentMinor),
          forecast,
          money(budget),
        );
}
