import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/money_display.dart';

/// "Số tiền" with the typed amount and a caret (52, or 44 for a transfer),
/// or the compact 40 amount without label on the details screen that
/// returns to the keypad on tap.
class AmountHeader extends StatelessWidget {
  const AmountHeader({
    required this.minor,
    required this.digits,
    required this.currency,
    required this.label,
    this.compact = false,
    this.transfer = false,
    this.onTap,
    super.key,
  });

  final BigInt minor;
  final int digits;
  final String currency;
  final String label;
  final bool compact;

  /// Transfer keypad screen: 44/50 amount, 34 caret, 22 ₫, label gap 4.
  final bool transfer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    // Board sizes: (font, line height, letter-spacing, caret, ₫).
    final (size, line, spacing, caret, mark) = compact
        ? (40.0, 44.0, -1.2, 0.0, 20.0)
        : transfer
        ? (44.0, 50.0, -1.4, 34.0, 22.0)
        : (52.0, 56.0, -1.6, 40.0, 24.0);
    final number = formatMoneyText(minor, digits, locale);
    final style = FreevaTypography.moneyDisplay.copyWith(
      fontSize: size,
      height: line / size,
      letterSpacing: spacing,
      color: minor == BigInt.zero && !compact ? c.textSecondary : c.textPrimary,
    );
    final amount = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: number),
          if (compact)
            const TextSpan(text: ' ')
          else
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: 2,
                height: caret,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: c.actionPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          TextSpan(
            text: MoneyDisplay.symbolFor(currency),
            style: FreevaTypography.titleL.copyWith(
              fontSize: mark,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
      style: style,
      softWrap: false,
    );
    return Semantics(
      button: onTap != null,
      label:
          '${S.of(context).txAmountLabel}, $number ${MoneyDisplay.symbolFor(currency)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: compact
              ? const EdgeInsets.symmetric(vertical: FreevaSpace.s2)
              : EdgeInsets.zero,
          child: Column(
            children: [
              if (!compact) ...[
                Text(
                  label,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
                SizedBox(height: transfer ? FreevaSpace.s1 : 6),
              ],
              FittedBox(fit: BoxFit.scaleDown, child: amount),
            ],
          ),
        ),
      ),
    );
  }
}
