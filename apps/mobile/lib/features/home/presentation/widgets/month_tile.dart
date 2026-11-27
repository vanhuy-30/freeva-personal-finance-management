import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../budgets/domain/budget.dart';
import '../../../budgets/presentation/widgets/budget_progress_card.dart';
import 'glance_painters.dart';
import 'glance_tile.dart';

/// Wide tile: budget ring with a "today" dot, what is left, a daily amount
/// and "Đã chi … / …". Without a budget: this month's spending and "Đặt
/// ngân sách".
class MonthTile extends StatelessWidget {
  const MonthTile({
    required this.monthLabel,
    required this.spentMinor,
    required this.digits,
    required this.today,
    required this.periodFrom,
    required this.periodTo,
    this.budget,
    super.key,
  });

  final String monthLabel;

  /// This month's spending in the main currency.
  final BigInt spentMinor;
  final int digits;
  final DateTime today;
  final DateTime periodFrom;
  final DateTime periodTo;
  final BudgetSummary? budget;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final b = budget;
    final total = periodTo.difference(periodFrom).inDays + 1;
    final passed = today.difference(periodFrom).inDays + 1;
    // Same rule as the spending forecast: days after today; none on the
    // last day.
    final daysLeft = total - passed;
    final remaining = b?.remainingMinor;
    final over = remaining != null && remaining < BigInt.zero;
    final percent = b == null ? null : (b.percentBps / 100).round();
    final title = b == null
        ? s.homeExpenseMonth(monthLabel)
        : over
        ? s.homeMonthOver(monthLabel)
        : s.homeMonthLeft(monthLabel);
    final big = b == null ? spentMinor : remaining!.abs();
    final note = glanceNote(context);
    return GlanceTile(
      minHeight: 0,
      padding: const EdgeInsets.all(FreevaSpace.s4),
      semanticsLabel: '$title ${money(big)}',
      onTap: () => context.push('/budgets'),
      child: Row(
        children: [
          // 72 on 320 pt screens so the text column keeps its tag.
          ProgressRing(
            size: context.isCompactScreen ? 72 : 88,
            stroke: context.isCompactScreen ? 8 : 9,
            value: b?.ratio ?? 0,
            color: b == null ? c.data1 : budgetStatusColor(context, b.status),
            track: c.bgTrack,
            marker: b == null ? null : (passed / total).clamp(0, 1).toDouble(),
            markerColor: c.textPrimary,
            markerBorder: c.cardBg,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  percent == null ? '–' : '$percent%',
                  style: FreevaTypography.titleM.copyWith(
                    fontSize: 18,
                    height: 1.1,
                    color: c.textPrimary,
                  ),
                ),
                if (percent != null)
                  Text(
                    s.homeMonthUsed,
                    style: note.copyWith(fontSize: 11, height: 1.2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title left, tag right; the tag drops under the title
                // when both do not fit (320 pt, large text).
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: FreevaSpace.s2,
                    runSpacing: FreevaSpace.s1,
                    children: [
                      Text(
                        title,
                        style: FreevaTypography.bodyS.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          color: c.textSecondary,
                        ),
                      ),
                      if (b != null)
                        GlanceTag(
                          text: budgetStatusLabel(s, b.status),
                          bg: _tagBg(context, b.status),
                          fg: _tagFg(context, b.status),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: FreevaSpace.s1),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    money(big),
                    style: FreevaTypography.headline.copyWith(
                      letterSpacing: -0.5,
                      color: over ? c.statusDanger : c.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: FreevaSpace.s1),
                if (b == null)
                  Text(
                    s.homeMonthSetBudget,
                    style: note.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.textLink,
                    ),
                  )
                else ...[
                  if (!over && daysLeft > 0)
                    Text(
                      s.homeMonthPerDay(
                        money(remaining! ~/ BigInt.from(daysLeft)),
                      ),
                      style: note,
                    ),
                  const SizedBox(height: FreevaSpace.s1),
                  Text(
                    s.budgetHomeLine(money(b.spentMinor), money(b.limitMinor)),
                    style: note,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _tagBg(BuildContext context, BudgetStatus status) =>
      switch (status) {
        BudgetStatus.healthy => context.colors.statusSuccessBg,
        BudgetStatus.warning => context.colors.statusWarningBg,
        _ => context.colors.statusDangerBg,
      };

  static Color _tagFg(BuildContext context, BudgetStatus status) =>
      switch (status) {
        BudgetStatus.healthy => context.colors.statusSuccess,
        BudgetStatus.warning => context.colors.statusWarning,
        _ => context.colors.statusDanger,
      };
}
