import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../money/money_text.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// How an amount is signed and coloured. Expense: ink and −. Income:
/// `money.income` and +. Transfer: muted, no sign. Red is never used here.
enum MoneyTone { plain, expense, income, transfer }

/// Tabular amount in minor units. On display amounts the currency mark sits
/// 6 px after the number at half size (16 on `moneyL`), weight 500, in the
/// muted colour; on small styles (≤ 17) it is part of the same span ("9.320.000
/// ₫" in one weight and colour). `hidden` masks it as •••••• and reads
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
    this.muted = false,
    this.semanticsLabel,
    this.currencyColor,
    this.currencySize,
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

  /// Keeps the sign but uses the muted colour (deleted transactions).
  final bool muted;
  final String? semanticsLabel;

  /// Colour of a separate ₫ mark (wash cards pass `text.onWash`); default
  /// `text.secondary`.
  final Color? currencyColor;

  /// Overrides the ₫ mark size; any size below the number's draws it as a
  /// separate weight-500 mark.
  final double? currencySize;

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
    final color = muted
        ? c.moneyTransfer
        : switch (tone) {
            MoneyTone.income => c.moneyIncome,
            MoneyTone.transfer => c.moneyTransfer,
            MoneyTone.expense => c.moneyExpense,
            MoneyTone.plain => style.color ?? c.textPrimary,
          };
    final text = hidden ? '••••••' : '$sign$number';
    final fontSize = style.fontSize ?? 15;
    final symbolSize =
        currencySize ??
        switch (fontSize) {
          >= 32 => fontSize / 2,
          >= 24 => 16.0,
          _ => fontSize,
        };
    // Small amounts keep ₫ in the number's own weight and colour.
    final inlineMark = symbolSize >= fontSize && fontSize <= 17;
    final mark = showCurrency;
    final base = style.copyWith(
      color: color,
      fontFeatures: style.fontFeatures ?? const [FontFeature.tabularFigures()],
    );
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
              TextSpan(
                text: text,
                style: hidden ? const TextStyle(letterSpacing: 2) : null,
              ),
              if (mark && inlineMark) TextSpan(text: ' ${symbolFor(currency)}'),
              if (mark && !inlineMark) ...[
                // A space sized so the gap before ₫ is 6 px (Inter 500).
                TextSpan(
                  text: ' ',
                  style: TextStyle(
                    fontSize: symbolSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 6 - symbolSize * 0.27,
                  ),
                ),
                TextSpan(
                  text: symbolFor(currency),
                  style: style.copyWith(
                    fontSize: symbolSize,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    color: currencyColor ?? c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          style: base,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
