import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../money/money_text.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// How an amount is signed and coloured. Expense: ink and −. Income:
/// `money.income` and +. Transfer: muted, no sign. Red is never used here.
enum MoneyTone { plain, expense, income, transfer }

/// Tabular amount in minor units. The currency mark sits after the number at
/// half size in the muted colour. `hidden` masks it as •••••• and reads
/// "balance hidden" to screen readers. Amounts never truncate with "…".
class MoneyDisplay extends StatelessWidget {
  const MoneyDisplay({
    required this.minor,
    required this.currency,
    this.minorDigits = 0,
    this.tone = MoneyTone.plain,
    this.style = FreevaTypography.moneyDisplay,
    this.showCurrency = true,
    this.hidden = false,
    this.semanticsLabel,
    super.key,
  });

  final BigInt minor;
  final String currency;
  final int minorDigits;
  final MoneyTone tone;
  final TextStyle style;

  /// Lists drop the ₫ mark; headline amounts keep it.
  final bool showCurrency;
  final bool hidden;
  final String? semanticsLabel;

  static String symbolFor(String currency) =>
      currency == 'VND' ? '₫' : currency;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final number = formatMoneyText(minor.abs(), minorDigits, locale);
    final sign = switch (tone) {
      MoneyTone.expense => '−',
      MoneyTone.income => '+',
      _ => minor.isNegative ? '−' : '',
    };
    final color = switch (tone) {
      MoneyTone.income => c.moneyIncome,
      MoneyTone.transfer => c.moneyTransfer,
      MoneyTone.expense => c.moneyExpense,
      MoneyTone.plain => style.color ?? c.textPrimary,
    };
    final text = hidden ? '••••••' : '$sign$number';
    // Half size on display amounts; same size on small ones.
    final fontSize = style.fontSize ?? 15;
    final symbolSize = fontSize >= 24 ? fontSize / 2 : fontSize;
    final mark = showCurrency;
    final display =
        identical(style, FreevaTypography.moneyDisplay) ||
        identical(style, FreevaTypography.moneyDisplayCompact);
    final maxScale = display
        ? FreevaTypography.moneyDisplayMaxScale
        : FreevaTypography.maxTextScale;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScale,
      child: Semantics(
        container: true,
        label: hidden
            ? S.of(context).balanceHiddenSemantics
            : semanticsLabel ?? '$sign$number ${symbolFor(currency)}',
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: text),
              if (mark)
                TextSpan(
                  text: ' ${symbolFor(currency)}',
                  style: style.copyWith(
                    fontSize: symbolSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
          style: style.copyWith(color: color),
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
