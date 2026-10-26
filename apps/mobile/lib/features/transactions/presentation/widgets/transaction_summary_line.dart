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
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final bold = base.copyWith(fontWeight: FontWeight.w600);
    String money(BigInt v, String code) =>
        '${formatMoneyText(v.abs(), digitsOf(code), locale)}${code == mainCurrency ? '' : ' $code'}';
    final parts = <List<InlineSpan>>[
      if (count) [TextSpan(text: s.txSearchResults(summary.count))],
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
    final spans = <InlineSpan>[
      for (final (i, part) in parts.indexed) ...[
        if (i > 0) TextSpan(text: count ? ' · ' : '    '),
        ...part,
      ],
    ];
    if (spans.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(TextSpan(children: spans), style: base),
    );
  }
}
