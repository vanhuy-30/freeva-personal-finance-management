import 'package:intl/intl.dart';

/// Unit marks for [compactMoney] ("k", "tr", "tỷ" in Vietnamese).
class CompactUnits {
  const CompactUnits({
    required this.thousand,
    required this.million,
    required this.billion,
  });

  final String thousand;
  final String million;
  final String billion;
}

/// Short amount for chart labels, at most three significant digits: 9,32tr,
/// 10,6tr, 450k. Only for display; the exact number is always available
/// elsewhere (chart semantics, lists).
String compactMoney(
  BigInt minor,
  int minorDigits,
  String locale,
  CompactUnits units,
) {
  var value = minor.abs().toDouble() / _pow10(minorDigits);
  final marks = ['', units.thousand, units.million, units.billion];
  var tier = 0;
  while (tier < 3 && (value >= 1000 || _roundsToThousand(value))) {
    value /= 1000;
    tier++;
  }
  final decimals = value >= 100 || tier == 0 ? 0 : (value >= 10 ? 1 : 2);
  final separator = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  var text = value.toStringAsFixed(decimals);
  if (decimals > 0) text = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${text.replaceFirst('.', separator)}${marks[tier]}';
}

bool _roundsToThousand(double value) => value >= 999.5 && value.round() >= 1000;

double _pow10(int digits) {
  var result = 1.0;
  for (var i = 0; i < digits; i++) {
    result *= 10;
  }
  return result;
}
