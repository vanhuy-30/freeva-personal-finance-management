import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/report_breakdown.dart';

/// Colour of slice [index]: `data.1` → `data.3`, then `data.4` for "Khác".
Color sliceColor(BuildContext context, int index, BreakdownSlice slice) {
  final c = context.colors;
  if (slice.isOther) return c.data4;
  return [c.data1, c.data2, c.data3][index % 3];
}

String sliceName(S s, BreakdownSlice slice, {bool withCount = false}) =>
    slice.name ??
    (withCount ? s.reportOtherCount(slice.categoryCount) : s.reportOther);

/// "Ăn uống 38%" next to the ring.
class BreakdownLegend extends StatelessWidget {
  const BreakdownLegend({required this.slices, super.key});

  final List<BreakdownSlice> slices;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final style = FreevaTypography.bodyS.copyWith(
      color: c.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        for (var i = 0; i < slices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Dot(sliceColor(context, i, slices[i])),
                const SizedBox(width: 8),
                Expanded(child: Text(sliceName(s, slices[i]), style: style)),
                const SizedBox(width: 8),
                Text(
                  '${slices[i].percent}%',
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One line per slice with its exact amount.
class BreakdownRows extends StatelessWidget {
  const BreakdownRows({
    required this.slices,
    required this.currency,
    required this.digits,
    required this.onOpen,
    super.key,
  });

  final List<BreakdownSlice> slices;
  final String currency;
  final int digits;
  final ValueChanged<BreakdownSlice> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Column(
      children: [
        for (var i = 0; i < slices.length; i++)
          Semantics(
            button: true,
            container: true,
            child: InkWell(
              onTap: () => onOpen(slices[i]),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : Border(top: BorderSide(color: c.borderDivider)),
                ),
                child: Row(
                  children: [
                    Dot(sliceColor(context, i, slices[i])),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sliceName(s, slices[i], withCount: true),
                        style: FreevaTypography.body.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MoneyDisplay(
                      minor: slices[i].minor,
                      currency: currency,
                      minorDigits: digits,
                      showCurrency: false,
                      style: FreevaTypography.titleM,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      LucideIcons.chevronRight,
                      size: FreevaSize.iconXs,
                      color: c.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key});

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
