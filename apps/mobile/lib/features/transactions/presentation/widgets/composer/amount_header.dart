import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/money_display.dart';

/// "Số tiền" with the typed amount (52) and a caret, or the compact 40
/// version on the details screen that returns to the keypad on tap.
class AmountHeader extends StatelessWidget {
  const AmountHeader({
    required this.minor,
    required this.digits,
    required this.currency,
    required this.label,
    this.compact = false,
    this.onTap,
    super.key,
  });

  final BigInt minor;
  final int digits;
  final String currency;
  final String label;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final size = compact ? 40.0 : 52.0;
    final number = formatMoneyText(minor, digits, locale);
    return Semantics(
      button: onTap != null,
      label:
          '${S.of(context).txAmountLabel}, $number ${MoneyDisplay.symbolFor(currency)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              label,
              style: FreevaTypography.bodyS.copyWith(
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: FreevaTypography.moneyDisplay.copyWith(
                      fontSize: size,
                      height: (size + 4) / size,
                      color: minor == BigInt.zero
                          ? c.textSecondary
                          : c.textPrimary,
                    ),
                  ),
                  if (!compact)
                    Container(
                      width: 2,
                      height: size * .75,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: c.actionPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 6),
                  Text(
                    MoneyDisplay.symbolFor(currency),
                    style: FreevaTypography.titleL.copyWith(
                      fontSize: size / 2.2,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
