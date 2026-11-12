import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/insight.dart';

/// The small picture under an insight's sentence: the budget bar with
/// "spent / limit · còn n ngày", or two comparison rows (S.1, S.2).
class InsightVisual extends StatelessWidget {
  const InsightVisual({required this.item, required this.digits, super.key});

  final Insight item;

  /// Minor digits of the list's currency.
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    return switch (item) {
      BudgetRiskInsight(
        :final spentMinor,
        :final limitMinor,
        :final percent,
        :final daysLeft,
      ) =>
        _BudgetBar(
          percent: percent,
          amounts: '${money(spentMinor)} / ${money(limitMinor)}',
          daysLeft: s.insightDaysLeft(daysLeft),
        ),
      OutlierInsight(:final amountMinor, :final usualMinor) => _Compare(
        rows: [
          (s.insightThisOne, amountMinor, c.data2, money(amountMinor)),
          (s.insightUsual, usualMinor, c.dataMuted, money(usualMinor)),
        ],
      ),
      CategoryChangeInsight(:final currentMinor, :final previousMinor) ||
      SpendTrendInsight(:final currentMinor, :final previousMinor) => _Compare(
        rows: [
          (s.insightThisMonth, currentMinor, c.data1, money(currentMinor)),
          (
            s.insightLastMonth,
            previousMinor,
            c.dataMuted,
            money(previousMinor),
          ),
        ],
      ),
    };
  }
}

/// Budget used: 8 high bar in the danger colour, amounts under it.
class _BudgetBar extends StatelessWidget {
  const _BudgetBar({
    required this.percent,
    required this.amounts,
    required this.daysLeft,
  });

  final int percent;
  final String amounts;
  final String daysLeft;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FreevaProgressBar(
          value: percent / 100,
          color: c.statusDanger,
          trackColor: c.borderDivider,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 2,
          children: [
            Text(
              amounts,
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            Text(daysLeft, style: style),
          ],
        ),
      ],
    );
  }
}

/// Two rows "label · bar · amount"; bars are scaled to the larger amount.
class _Compare extends StatelessWidget {
  const _Compare({required this.rows});

  final List<(String, BigInt, Color, String)> rows;

  /// Board rows use the browser's normal line height.
  static const _line = 1.2;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = rows
        .map((r) => r.$2)
        .fold(BigInt.zero, (a, b) => b > a ? b : a);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (label, minor, color, text)) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: FreevaSpace.s2),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 78),
                child: Text(
                  label,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    height: _line,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ExcludeSemantics(
                  child: FreevaProgressBar(
                    value: top == BigInt.zero ? 0 : minor / top,
                    color: color,
                    // Board #F1F3F8; bg.subtle keeps the muted bar visible
                    // in dark mode.
                    trackColor: c.bgSubtle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 84),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    height: _line,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
