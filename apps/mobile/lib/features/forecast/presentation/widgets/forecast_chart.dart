import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/balance_forecast.dart';
import 'forecast_labels.dart';

/// Balance today and at the end of each month. Bars are 44 wide (10/4
/// corners), the last one primary, the others `data.muted`. More columns than fit scroll sideways; the exact amounts are in the semantics.
class ForecastChart extends StatelessWidget {
  const ForecastChart({
    required this.forecast,
    required this.digits,
    required this.hidden,
    super.key,
  });

  final BalanceForecast forecast;
  final int digits;
  final bool hidden;

  static const _barWidth = 44.0;
  static const _barMax = 108.0;
  static const _barMin = 4.0;
  static const _slot = _barWidth + 10;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    // Two 12/1.25 label lines grow with the text size; the bars do not.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final points = [
      (label: s.forecastToday, value: forecast.startingBalanceMinor),
      for (final m in forecast.months)
        (label: forecastMonthShort(s, m.month), value: m.closingMinor),
    ];
    final peak = points.fold<BigInt>(
      BigInt.zero,
      (top, p) => p.value > top ? p.value : top,
    );
    double height(BigInt value) {
      if (peak == BigInt.zero || value <= BigInt.zero) return _barMin;
      return (_barMax * value.toDouble() / peak.toDouble()).clamp(
        _barMin,
        _barMax,
      );
    }

    final exact = [
      for (final p in points)
        '${p.label} ${hidden ? '' : formatMoneyText(p.value, digits, locale)}',
    ].join(', ');
    Widget column(int i) {
      final p = points[i];
      final last = i == points.length - 1;
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            hidden ? '•••' : _short(p.value, units, locale),
            maxLines: 1,
            style: FreevaTypography.label.copyWith(
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: _barWidth,
            height: height(p.value),
            decoration: BoxDecoration(
              color: last ? c.actionPrimary : c.dataMuted,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
                bottom: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            p.label,
            maxLines: 1,
            style: FreevaTypography.label.copyWith(
              height: 1.25,
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
      );
    }

    return Semantics(
      container: true,
      image: true,
      label: s.forecastChartSemantics(exact),
      child: ExcludeSemantics(
        child: SizedBox(
          height: _barMax + 12 + 2 * (15 * scale).ceilToDouble(),
          child: LayoutBuilder(
            builder: (context, box) {
              final fits = points.length * _slot <= box.maxWidth + 10;
              final row = Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < points.length; i++)
                    fits
                        ? Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: column(i),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              right: i == points.length - 1 ? 0 : 10,
                            ),
                            child: column(i),
                          ),
                ],
              );
              return fits
                  ? row
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: row,
                    );
            },
          ),
        ),
      ),
    );
  }

  String _short(BigInt value, CompactUnits units, String locale) {
    final text = compactMoney(value, digits, locale, units);
    return value.isNegative ? '−$text' : text;
  }
}
