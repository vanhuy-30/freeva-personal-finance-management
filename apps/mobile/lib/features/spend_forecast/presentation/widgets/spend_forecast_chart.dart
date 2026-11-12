import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/spending_forecast.dart';
import 'spend_forecast_chart_painter.dart';
import 'spend_forecast_labels.dart';

/// S.3 cumulative chart, 176 high: spent so far as an area under a line,
/// a dashed line from today to the month-end forecast, the budget as a
/// dotted line, and "01/11 · Hôm nay · 30/11" under it. Read out as one
/// sentence.
class SpendForecastChart extends StatelessWidget {
  const SpendForecastChart({
    required this.forecast,
    required this.period,
    required this.digits,
    super.key,
  });

  final SpendingForecast forecast;
  final SpendForecastPeriod? period;
  final int digits;

  static const height = 176.0;
  static const _labelTop = 157.0;

  /// Room between today's label centre and an edge date.
  static const _edgeGap = 56.0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    final budget = forecast.budgetLimitMinor;
    final small = FreevaTypography.label.copyWith(
      fontSize: 11,
      height: 1,
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    final range = period;
    return Semantics(
      container: true,
      image: true,
      label: forecastChartLabel(s, forecast, money),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final g = SpendChartGeometry.of(forecast, range, box.maxWidth);
              final todayX = g.x(g.todayIndex);
              // "Hôm nay" wins over an edge date it would run into.
              final showFrom = todayX - SpendChartGeometry.left > _edgeGap;
              final showTo = g.right - todayX > _edgeGap;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: SpendForecastPainter(
                        geometry: g,
                        colors: SpendChartColors.of(c),
                      ),
                    ),
                  ),
                  if (budget != null)
                    Positioned(
                      left: SpendChartGeometry.left,
                      top: g.y(budget) - 15,
                      child: Text(
                        s.spendForecastBudget(
                          compactMoney(budget, digits, locale, units),
                        ),
                        style: small,
                      ),
                    ),
                  if (range != null) ...[
                    if (showFrom)
                      Positioned(
                        left: SpendChartGeometry.left,
                        top: _labelTop,
                        child: Text(_dayMonth(range.from), style: small),
                      ),
                    if (showTo)
                      Positioned(
                        right: box.maxWidth - g.right,
                        top: _labelTop,
                        child: Text(_dayMonth(range.to), style: small),
                      ),
                  ],
                  Positioned(
                    left: (todayX - 40).clamp(0, box.maxWidth - 80),
                    width: 80,
                    top: _labelTop,
                    child: Text(
                      s.spendForecastToday,
                      textAlign: TextAlign.center,
                      style: small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// `yyyy-MM-dd` → `dd/MM`.
  static String _dayMonth(String day) =>
      '${day.substring(8, 10)}/${day.substring(5, 7)}';
}
