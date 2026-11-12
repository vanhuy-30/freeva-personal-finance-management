import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/spending_forecast.dart';
import 'forecast_chip.dart';
import 'spend_forecast_bar.dart';
import 'spend_forecast_labels.dart';

/// Top of Phân tích (S.2): "Dự báo chi cuối tháng N", risk chip, the
/// projected total, the spent/forecast bar and its legend. Opens S.3. Before
/// there are enough days it only says so and is not a button.
class SpendForecastCard extends StatelessWidget {
  const SpendForecastCard({
    required this.forecast,
    required this.period,
    required this.digits,
    required this.onTap,
    super.key,
  });

  final SpendingForecast forecast;
  final SpendForecastPeriod? period;
  final int digits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final label = s.spendForecastCardLabel(forecastMonth(s, locale, period));
    final chip = riskChip(s, forecast.risk);
    final total = forecast.forecastMinor;
    final head = Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
        ),
        if (total != null && chip != null) ...[
          const SizedBox(width: FreevaSpace.s2),
          ForecastChip(label: chip.$1, tone: chip.$2),
        ],
      ],
    );
    if (!forecast.ready || total == null) {
      return Semantics(
        container: true,
        child: FreevaCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              const SizedBox(height: 6),
              Text(
                s.spendForecastNotYet,
                style: FreevaTypography.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final spent = s.spendForecastSpent(money(forecast.spentMinor));
    final compare = forecastCompare(s, forecast, money);
    return Semantics(
      button: true,
      container: true,
      label: [
        label,
        money(total),
        if (chip != null) chip.$1,
        spent,
        compare,
      ].join(', '),
      child: FreevaCard(
        padding: const EdgeInsets.all(18),
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      money(total),
                      maxLines: 1,
                      style: FreevaTypography.moneyL.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s2),
                  Icon(
                    LucideIcons.chevronRight,
                    size: FreevaSize.iconSm,
                    color: c.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: FreevaSpace.s3),
              SpendForecastBar(
                spentMinor: forecast.spentMinor,
                forecastMinor: total,
                budgetMinor: forecast.budgetLimitMinor,
              ),
              const SizedBox(height: FreevaSpace.s3),
              _Legend(
                spent: spent,
                compare: compare,
                budget: forecast.budgetLimitMinor != null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "● Đã chi …" left, "| Ngân sách …" (or "Tháng trước …") right.
class _Legend extends StatelessWidget {
  const _Legend({
    required this.spent,
    required this.compare,
    required this.budget,
  });

  final String spent;
  final String compare;
  final bool budget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        _Dot(color: c.actionPrimary, width: 8, height: 8),
        const SizedBox(width: 6),
        Expanded(child: Text(spent, style: style)),
        if (budget) ...[
          _Dot(color: c.textPrimary, width: 2, height: 10),
          const SizedBox(width: 6),
        ],
        Text(compare, style: style),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.width, required this.height});

  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(FreevaRadius.full),
    ),
  );
}
