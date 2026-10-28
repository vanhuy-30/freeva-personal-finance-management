import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/budget.dart';

Color budgetStatusColor(BuildContext context, BudgetStatus status) {
  final c = context.colors;
  return switch (status) {
    BudgetStatus.healthy => c.data1,
    BudgetStatus.warning => FreevaPrimitive.amber500,
    BudgetStatus.critical || BudgetStatus.over => c.statusDanger,
  };
}

String budgetStatusLabel(S s, BudgetStatus status) => switch (status) {
  BudgetStatus.healthy => s.budgetStatusHealthy,
  BudgetStatus.warning => s.budgetStatusWarning,
  BudgetStatus.critical => s.budgetStatusCritical,
  BudgetStatus.over => s.budgetStatusOver,
};

/// Progress card used on Reports (month) and the budget editor header.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    required this.summary,
    required this.minorDigits,
    this.onTap,
    super.key,
  });

  final BudgetSummary summary;
  final int minorDigits;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final color = budgetStatusColor(context, summary.status);
    final percent = (summary.percentBps / 100).toStringAsFixed(
      summary.percentBps % 100 == 0 ? 0 : 1,
    );
    String money(BigInt value) =>
        formatMoneyText(value, minorDigits, locale);
    return FreevaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.budgetUsedPercent(percent),
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: Text(
                  budgetStatusLabel(s, summary.status),
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaProgressBar(value: summary.ratio, color: color),
          const SizedBox(height: FreevaSpace.s3),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: s.budgetSpentLabel,
                  value: money(summary.spentMinor),
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: _Stat(
                  label: s.budgetRemainingLabel,
                  value: money(summary.remainingMinor),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s2),
          Text(
            s.budgetLimitLine(
              money(summary.spentMinor),
              money(summary.limitMinor),
            ),
            style: FreevaTypography.label.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}
