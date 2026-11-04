import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money/money_input_formatter.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Big centred amount input of a sheet: 40/600 tabular figures, blue caret,
/// currency symbol after it (GoalMove, BillPaid).
class SheetAmountField extends StatelessWidget {
  const SheetAmountField({
    required this.controller,
    required this.digits,
    required this.locale,
    required this.symbol,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final int digits;
  final String locale;
  final String symbol;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = FreevaTypography.moneyDisplay.copyWith(
      height: 44 / 40,
      letterSpacing: -1.4,
      color: c.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28, maxWidth: 260),
            child: TextField(
              controller: controller,
              autofocus: true,
              textAlign: TextAlign.end,
              style: style,
              cursorColor: c.actionPrimary,
              cursorWidth: 2,
              cursorHeight: 28,
              keyboardType: TextInputType.numberWithOptions(
                decimal: digits > 0,
              ),
              inputFormatters: [
                MoneyInputFormatter(minorDigits: digits, locale: locale),
                LengthLimitingTextInputFormatter(20),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          symbol,
          style: FreevaTypography.titleS.copyWith(
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
