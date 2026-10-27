import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/report.dart';
import '../../domain/report_trend.dart';
import 'trend_labels.dart';

/// Bars of spending per period: the viewed (last) one in `data.1`, the others
/// muted. Value labels use short amounts; the semantics read every exact one.
class TrendBars extends StatelessWidget {
  const TrendBars({
    required this.series,
    required this.kind,
    required this.currency,
    required this.digits,
    super.key,
  });

  final TrendSeries series;
  final ReportPeriodKind kind;
  final String currency;
  final int digits;

  static const _plot = 110.0;

  /// Band above the tallest bar (where the budget line goes, 18 on RepMonth).
  static const _top = 18.0;
  static const _barWidth = 26.0;

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
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final peak = series.peak;
    final items = [
      for (final bar in series.bars)
        s.reportAmount(
          trendBarLabel(s, kind, bar, locale),
          formatMoneyText(bar.expense, digits, locale),
          currency,
        ),
    ].join(', ');
    return Semantics(
      container: true,
      image: true,
      label: s.reportTrendSemantics(series.bars.length, items),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final slot = box.maxWidth / series.bars.length;
            // Eight narrow columns cannot all carry a label at large text.
            final labelAll = slot / scale >= 40;
            final axisAll = slot / scale >= 28;
            return SizedBox(
              // Two label lines (value, axis) grow with the text size; 170 at
              // 100%, as on the board.
              height: _top + _plot + 12 + 2 * 15 * scale,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < series.bars.length; i++)
                    Expanded(
                      child: _Column(
                        label:
                            series.bars[i].expense == BigInt.zero ||
                                !(labelAll || series.bars[i].current)
                            ? null
                            : compactMoney(
                                series.bars[i].expense,
                                digits,
                                locale,
                                units,
                              ),
                        axis: axisAll || (series.bars.length - 1 - i).isEven
                            ? trendBarLabel(s, kind, series.bars[i], locale)
                            : '',
                        height: peak == BigInt.zero
                            ? 4
                            : (_plot *
                                      (series.bars[i].expense *
                                              BigInt.from(1000) ~/
                                              peak)
                                          .toInt() /
                                      1000)
                                  .clamp(4, _plot),
                        color: series.bars[i].current ? c.data1 : c.dataMuted,
                        strong: series.bars[i].current,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.label,
    required this.axis,
    required this.height,
    required this.color,
    required this.strong,
  });

  final String? label;
  final String axis;
  final double height;
  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = FreevaTypography.label.copyWith(
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (label != null)
          Text(
            label!,
            maxLines: 1,
            softWrap: false,
            style: base.copyWith(
              fontWeight: FontWeight.w600,
              color: strong ? c.textPrimary : c.textOnWash,
            ),
          ),
        const SizedBox(height: 6),
        Container(
          width: TrendBars._barWidth,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
              bottom: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          axis,
          maxLines: 1,
          softWrap: false,
          style: base.copyWith(
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
            color: strong ? c.textPrimary : c.textSecondary,
          ),
        ),
      ],
    );
  }
}
