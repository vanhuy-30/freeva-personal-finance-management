import 'money_text.dart';

/// Quantities (grams of gold, shares, coins) are decimals with up to 8
/// digits. They are held as a [BigInt] scaled by 10^8, never a double, the
/// same way the API does the arithmetic.
const quantityDigits = 8;

final _scale = BigInt.from(10).pow(quantityDigits);

/// The unit quantity `1` in scaled form.
BigInt get quantityOne => _scale;

/// Scaled quantity from typed text; null when not a number. Zero and
/// negatives parse (callers decide), more than 8 decimals is refused.
BigInt? parseQuantity(String text, String locale) =>
    parseMoneyText(text.trim(), quantityDigits, locale);

/// Display text without trailing zeros: 3 → "3", 0.5 → "0,5" (vi).
String formatQuantity(BigInt scaled, String locale) {
  final full = formatMoneyText(scaled, quantityDigits, locale, grouped: false);
  final sep = RegExp(r'[^0-9\-−]').firstMatch(full)?.group(0);
  if (sep == null) return full;
  final trimmed = full.replaceFirst(RegExp('0+\$'), '');
  return trimmed.endsWith(sep)
      ? trimmed.substring(0, trimmed.length - sep.length)
      : trimmed;
}

/// API text: "3" or "0.12345678", always with a dot.
String quantityToApi(BigInt scaled) {
  final digits = scaled.abs().toString().padLeft(quantityDigits + 1, '0');
  final split = digits.length - quantityDigits;
  final fraction = digits.substring(split).replaceFirst(RegExp(r'0+$'), '');
  final text = fraction.isEmpty
      ? digits.substring(0, split)
      : '${digits.substring(0, split)}.$fraction';
  return scaled.isNegative ? '-$text' : text;
}

/// Money for [scaledQuantity] at [priceMinor] a unit, rounded half up:
/// 3 × 7.200.000 = 21.600.000. Non-negative inputs.
BigInt quantityTotalMinor(BigInt scaledQuantity, BigInt priceMinor) =>
    (scaledQuantity * priceMinor + _scale ~/ BigInt.two) ~/ _scale;

/// Scaled quantity from API text ("0.12345678", always a dot); null when the
/// text is not a decimal with up to 8 digits.
BigInt? parseQuantityApi(String text) =>
    parseMoneyText(text, quantityDigits, 'en');

/// Cost removed from a position by selling [sold] of [held]: the
/// proportional share of [costBasisMinor], rounded half up; selling
/// everything takes all of it (the API's rule, so previews match).
BigInt soldCostMinor(BigInt costBasisMinor, BigInt held, BigInt sold) {
  if (sold >= held) return costBasisMinor;
  return (costBasisMinor * sold * BigInt.two + held) ~/ (held * BigInt.two);
}
