import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/allocation_bar.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../features/reports/domain/report.dart';
import '../../domain/overview.dart';
import 'spending_empty_row.dart';
import 'spending_legend.dart';

/// "Chi tháng 10": total, allocation bar (data.1 → data.3, then muted for
/// "Khác", data.4) and a % legend. Tapping opens Reports. Empty month shows the
/// empty line with "Ghi chi" on the same row.
class SpendingBlock extends StatelessWidget {
  const SpendingBlock({
    required this.breakdown,
    required this.currency,
    required this.minorDigits,
    required this.monthLabel,
    required this.otherCurrencies,
    required this.digitsOf,
    super.key,
  });

  final SpendingBreakdown breakdown;
  final String currency;
  final int minorDigits;
  final String monthLabel;
  final List<CashflowTotal> otherCurrencies;
  final int Function(String) digitsOf;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final palette = [c.data1, c.data2, c.data3];
    Color colorAt(int i, SpendingSlice slice) =>
        slice.name == null || i >= palette.length ? c.data4 : palette[i];
    final empty = breakdown.slices.isEmpty;
    final locale = Localizations.localeOf(context).toString();
    // The empty month card is tighter (12) than the filled one (14).
    final gap = empty ? FreevaSpace.s3 : 14.0;
    return FreevaCard(
      onTap: empty ? null : () => context.go('/reports'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.homeExpenseMonth(monthLabel),
                  style: FreevaTypography.titleM.copyWith(
                    height: 1.2,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (!empty)
                MoneyDisplay(
                  minor: breakdown.total,
                  currency: currency,
                  minorDigits: minorDigits,
                  style: FreevaTypography.titleM.copyWith(height: 1.2),
                ),
            ],
          ),
          SizedBox(height: gap),
          AllocationBar(
            parts: [
              for (final (i, slice) in breakdown.slices.indexed)
                AllocationPart(slice.minor.toDouble(), colorAt(i, slice)),
            ],
          ),
          SizedBox(height: gap),
          if (empty)
            const SpendingEmptyRow()
          else
            SpendingLegend(
              items: [
                for (final (i, slice) in breakdown.slices.indexed)
                  (
                    slice.name ?? s.homeSpendOther,
                    slice.percent,
                    colorAt(i, slice),
                  ),
              ],
            ),
          for (final row in otherCurrencies)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                s.homeOtherCurrencySpend(
                  row.currency,
                  formatMoneyText(
                    row.expenseMinor.abs(),
                    digitsOf(row.currency),
                    locale,
                  ),
                ),
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
