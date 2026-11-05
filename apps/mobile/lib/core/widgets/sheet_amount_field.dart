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
    this.fontSize = 40,
    this.lineHeight = 44,
    this.caretHeight = 28,
    this.autofocus = true,
    super.key,
  });

  final TextEditingController controller;
  final int digits;
  final String locale;
  final String symbol;
  final VoidCallback onChanged;

  /// 40/44 in a sheet; 48/52 with a 34 caret on a form page (DebtAdd).
  final double fontSize;
  final double lineHeight;
  final double caretHeight;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = FreevaTypography.moneyDisplay.copyWith(
      fontSize: fontSize,
      height: lineHeight / fontSize,
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
            constraints: BoxConstraints(minWidth: 28, maxWidth: fontSize * 6.5),
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              textAlign: TextAlign.end,
              style: style,
              cursorColor: c.actionPrimary,
              cursorWidth: 2,
              cursorHeight: caretHeight,
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
