import 'money_text.dart';

/// "+40.950.000" or "−6.000.000"; zero has no sign.
String signedMoney(BigInt minor, int digits, String locale) {
  final sign = minor.isNegative ? '−' : (minor == BigInt.zero ? '' : '+');
  return '$sign${formatMoneyText(minor.abs(), digits, locale)}';
}
