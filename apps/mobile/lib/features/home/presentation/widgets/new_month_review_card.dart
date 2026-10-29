import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/overview.dart';

/// Start of a new month: "Xem lại tháng 10 · Chi … · Thu …", opens month review.
class NewMonthReviewCard extends StatelessWidget {
  const NewMonthReviewCard({
    required this.monthLabel,
    required this.on,
    required this.flow,
    required this.minorDigits,
    super.key,
  });

  final String monthLabel;

  /// Anchor date of the reviewed fiscal month (`period.from`).
  final String on;
  final MonthFlow flow;
  final int minorDigits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, minorDigits, locale);
    return FreevaCard(
      list: true,
      onTap: () => context.push('/reports/month-review?on=$on'),
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s4,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: Icon(
              LucideIcons.chartPie,
              size: FreevaSize.iconInline,
              color: c.tintBlueFg,
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.homeReviewMonth(monthLabel),
                  style: FreevaTypography.titleM.copyWith(
                    height: 1.2,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  s.homeReviewLine(money(flow.expense), money(flow.income)),
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.25,
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: FreevaSize.iconChip,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}
