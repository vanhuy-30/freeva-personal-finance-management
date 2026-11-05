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
    this.insight = const MonthInsight(),
    super.key,
  });

  final String monthLabel;

  /// Anchor date of the reviewed fiscal month (`period.from`).
  final String on;
  final MonthFlow flow;
  final int minorDigits;

  /// Optional lines under the header; absent lines are not drawn.
  final MonthInsight insight;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(s, c, money),
          if (!insight.isEmpty) ...[
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 1, color: c.borderDivider),
            if (insight.topIncrease case final up?)
              _InsightLine(
                icon: LucideIcons.trendingUp,
                color: c.statusWarning,
                label: s.homeReviewTopIncrease(up.name),
                value: '+${money(up.deltaMinor)}',
              ),
            if (insight.overBudget case final over?)
              _InsightLine(
                icon: LucideIcons.triangleAlert,
                color: c.statusDanger,
                label: s.homeReviewOverBudget(over.percent),
                value: '${money(over.spentMinor)} / ${money(over.limitMinor)}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _header(S s, FreevaColors c, String Function(BigInt) money) {
    return Row(
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
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            // Label left, value right; at large text the value drops to its
            // own line instead of overflowing.
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 2,
              children: [
                Text(
                  label,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  value,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
