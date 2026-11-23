import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// "6,1%" or "12,34%" with at most one decimal, from basis points.
String percentText(int bps, String locale) =>
    '${NumberFormat('#,##0.0', locale).format(bps.abs() / 100)}%';

/// "▲ 6,1% so tháng trước": the arrow and number carry the meaning by colour
/// (green when it is good news, red when not), the grey words say against
/// what. A zero change is plain grey with no arrow.
///
/// [higherIsBetter] says which direction is good: income and savings, yes;
/// spending, no. With [points] the number is a difference of two rates and
/// reads "4,4 điểm" instead of a percent. Wraps instead of cutting at large text.
class ChangeLine extends StatelessWidget {
  const ChangeLine({
    required this.bps,
    required this.higherIsBetter,
    this.compare,
    this.points = false,
    super.key,
  });

  final int bps;
  final bool higherIsBetter;

  /// The words after the number; null for none.
  final String? compare;
  final bool points;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final up = bps > 0;
    final flat = bps == 0;
    final good = up == higherIsBetter;
    final tone = flat
        ? c.textSecondary
        : good
        ? c.moneyIncome
        : c.statusDanger;
    final number = points
        ? s.reportChangePoints(
            NumberFormat('#,##0.0', locale).format(bps.abs() / 100),
          )
        : percentText(bps, locale);
    final arrow = flat
        ? ''
        : up
        ? '▲ '
        : '▼ ';
    final strong = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w600,
      color: tone,
    );
    final soft = FreevaTypography.label.copyWith(
      fontSize: 10.5,
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    return Semantics(
      container: true,
      label: [
        up
            ? number
            : flat
            ? number
            : '−$number',
        if (compare != null) compare!,
      ].join(' '),
      excludeSemantics: true,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 3,
        children: [
          Text('$arrow$number', style: strong),
          if (compare != null) Text(compare!, style: soft),
        ],
      ),
    );
  }
}
