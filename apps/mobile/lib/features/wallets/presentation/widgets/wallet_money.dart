import 'package:intl/intl.dart';

import '../../domain/wallet.dart';

/// Decimal text and minor units are converted without floating point arithmetic.
BigInt? parseWalletMoney(String text, WalletCurrency currency, String locale) {
  final separator = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  final value = text.trim();
  final pattern = RegExp('^-?[0-9]+(?:${RegExp.escape(separator)}[0-9]+)?\$');
  if (!pattern.hasMatch(value)) return null;
  final parts = value.replaceFirst('-', '').split(separator);
  final fraction = parts.length == 2 ? parts[1] : '';
  if (fraction.length > currency.minorDigits) return null;
  final minor = BigInt.parse(
    '${parts[0]}${fraction.padRight(currency.minorDigits, '0')}',
  );
  return value.startsWith('-') ? -minor : minor;
}

String walletMoney(
  BigInt minor,
  WalletCurrency currency,
  String locale, {
  bool grouped = true,
}) {
  final symbols = NumberFormat.decimalPattern(locale).symbols;
  final digits = minor.abs().toString().padLeft(currency.minorDigits + 1, '0');
  final split = digits.length - currency.minorDigits;
  var whole = digits.substring(0, split);
  if (grouped) {
    whole = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => symbols.GROUP_SEP,
    );
  }
  final fraction = currency.minorDigits == 0
      ? ''
      : '${symbols.DECIMAL_SEP}${digits.substring(split)}';
  return '${minor.isNegative ? symbols.MINUS_SIGN : ''}$whole$fraction';
}
