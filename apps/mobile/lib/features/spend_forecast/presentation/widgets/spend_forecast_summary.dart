import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/spending_forecast.dart';
import 'forecast_chip.dart';
import 'spend_forecast_chart.dart';
import 'spend_forecast_labels.dart';

/// S.3 card: "Cuối tháng N có thể chi khoảng", risk chip, the total, how
/// far over the budget, the cumulative chart and its legend.
class SpendForecastSummary extends StatelessWidget {
  const SpendForecastSummary({
    required this.forecast,
    required this.period,
    required this.digits,
    super.key,
  });

  final SpendingForecast forecast;
  final SpendForecastPeriod? period;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final chip = riskChip(s, forecast.risk);
    final over = forecast.overBudgetMinor;
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.spendForecastHeadline(forecastMonth(s, locale, period)),
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              if (chip != null) ...[
                const SizedBox(width: FreevaSpace.s2),
                ForecastChip(label: chip.$1, tone: chip.$2),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            money(forecast.forecastMinor ?? BigInt.zero),
            maxLines: 1,
            style: FreevaTypography.moneyDisplayCompact.copyWith(
              letterSpacing: -0.8,
              color: c.textPrimary,
            ),
          ),
          if (over != null && over > BigInt.zero) ...[
            const SizedBox(height: 10),
            Text(
              s.spendForecastOver(money(over)),
              style: FreevaTypography.bodyS.copyWith(
                fontWeight: FontWeight.w500,
                color: c.statusDanger,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SpendForecastChart(
            forecast: forecast,
            period: period,
            digits: digits,
          ),
          const SizedBox(height: 10),
          const _ChartLegend(),
        ],
      ),
    );
  }
}

/// "▬ Đã chi   ┄ Dự báo".
class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final style = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    return ExcludeSemantics(
      child: Row(
        children: [
          Container(
            width: 14,
            height: 3,
            decoration: BoxDecoration(
              color: c.actionPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(s.spendForecastLegendSpent, style: style),
          const SizedBox(width: 14),
          CustomPaint(
            size: const Size(14, 2),
            painter: _DashPainter(c.statusDanger),
          ),
          const SizedBox(width: 6),
          Text(s.spendForecastLegendForecast, style: style),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 4, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
