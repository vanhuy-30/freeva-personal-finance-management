import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';

import 'money_text.dart';

/// Groups thousands while typing ("11450000" → "11.450.000" in vi) and keeps
/// at most [minorDigits] after the decimal separator. Text only: amounts are
/// read back with [parseGroupedMoney], never through a double.
class MoneyInputFormatter extends TextInputFormatter {
  MoneyInputFormatter({
    required this.minorDigits,
    required String locale,
    this.allowNegative = false,
  }) : _symbols = NumberFormat.decimalPattern(locale).symbols;

  final int minorDigits;
  final bool allowNegative;
  final NumberSymbols _symbols;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final decimal = _symbols.DECIMAL_SEP;
    final group = _symbols.GROUP_SEP;
    var text = newValue.text;
    final negative = allowNegative && text.trimLeft().startsWith('-');
    final whole = StringBuffer();
    final fraction = StringBuffer();
    var inFraction = false;
    for (final char in text.split('')) {
      if (RegExp(r'[0-9]').hasMatch(char)) {
        (inFraction ? fraction : whole).write(char);
      } else if (char == decimal && minorDigits > 0 && !inFraction) {
        inFraction = true;
      }
    }
    final digits = whole.toString().replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final grouped = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => group,
    );
    final cents = fraction.toString();
    text = [
      if (negative) '-',
      grouped,
      if (inFraction)
        '$decimal${cents.length > minorDigits ? cents.substring(0, minorDigits) : cents}',
    ].join();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Minor units from text typed with [MoneyInputFormatter]; null when it is
/// not a number. Empty text is null too: callers decide what empty means.
BigInt? parseGroupedMoney(String text, int minorDigits, String locale) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  final plain = text
      .replaceAll(symbols.GROUP_SEP, '')
      .replaceAll(' ', '')
      .replaceAll(' ', '')
      .replaceAll('−', '-');
  if (plain.isEmpty || plain == '-') return null;
  return parseMoneyText(plain, minorDigits, locale);
}
