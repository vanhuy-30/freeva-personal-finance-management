import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/transaction.dart';

/// "Thu +18.500.000   Chi −9.320.000" for the whole filtered result, in the
/// profile currency first. With [count]: "3 kết quả · Chi −185.000".
class TransactionSummaryLine extends StatelessWidget {
  const TransactionSummaryLine({
    required this.summary,
    required this.mainCurrency,
    required this.digitsOf,
    this.count = false,
    super.key,
  });

  final TransactionSummary summary;
  final String mainCurrency;
  final int Function(String) digitsOf;
  final bool count;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final totals = [...summary.totals]
      ..sort(
        (a, b) => a.currency == mainCurrency
            ? -1
            : b.currency == mainCurrency
            ? 1
            : 0,
      );
    final base = FreevaTypography.bodyS.copyWith(
      height: 16 / 13,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final bold = base.copyWith(fontWeight: FontWeight.w600);
    String money(BigInt v, String code) =>
        '${formatMoneyText(v.abs(), digitsOf(code), locale)}${code == mainCurrency ? '' : ' $code'}';
    final parts = <List<InlineSpan>>[
      for (final t in totals) ...[
        if (t.income != BigInt.zero)
          [
            TextSpan(text: '${s.transactionIncome} '),
            TextSpan(
              text: '+${money(t.income, t.currency)}',
              style: bold.copyWith(color: c.moneyIncome),
            ),
          ],
        if (t.expense != BigInt.zero)
          [
            TextSpan(text: '${s.transactionExpense} '),
            TextSpan(
              text: '−${money(t.expense, t.currency)}',
              style: bold.copyWith(color: c.moneyExpense),
            ),
          ],
      ],
    ];
    if (parts.isEmpty && !count) return const SizedBox.shrink();
    // Board: totals 20 apart; with a count, "3 kết quả" left and the
    // totals right.
    final totalsWrap = Wrap(
      spacing: FreevaSpace.s5,
      children: [
        for (final part in parts)
          Text.rich(TextSpan(children: part), style: base),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: count
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.txSearchResults(summary.count), style: base),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: totalsWrap,
                  ),
                ),
              ],
            )
          : totalsWrap,
    );
  }
}
