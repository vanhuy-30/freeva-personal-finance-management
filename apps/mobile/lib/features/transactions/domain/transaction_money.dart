final BigInt int64Min = BigInt.parse('-9223372036854775808');
final BigInt int64Max = BigInt.parse('9223372036854775807');

bool inInt64(BigInt value) => value >= int64Min && value <= int64Max;

/// Positive `Decimal(18,8)` rate, normalized to 8 fractional digits.
String? normalizeRate(String value) {
  final trimmed = value.trim();
  if (!RegExp(r'^\d{1,10}(?:\.\d{1,8})?$').hasMatch(trimmed)) return null;
  final parts = trimmed.split('.');
  final fraction = parts.length == 2 ? parts[1] : '';
  final scaled = BigInt.parse('${parts[0]}${fraction.padRight(8, '0')}');
  if (scaled <= BigInt.zero) return null;
  return '${parts[0]}.${fraction.padRight(8, '0')}';
}

/// Exact destination minor units for a negative source. Null when the rate
/// is invalid or the result needs a fractional minor unit.
BigInt? convertedMinor(
  BigInt source,
  String rate,
  int fromDigits,
  int toDigits,
) {
  if (fromDigits < 0 ||
      fromDigits > 18 ||
      toDigits < 0 ||
      toDigits > 18 ||
      source >= BigInt.zero) {
    return null;
  }
  final normalized = normalizeRate(rate);
  if (normalized == null) return null;
  final rateMinor = BigInt.parse(normalized.replaceAll('.', ''));
  final numerator = -source * rateMinor * _pow10(toDigits);
  final denominator = BigInt.from(100000000) * _pow10(fromDigits);
  if (numerator % denominator != BigInt.zero) return null;
  final destination = numerator ~/ denominator;
  if (destination <= BigInt.zero || !inInt64(destination)) return null;
  return destination;
}

BigInt _pow10(int digits) {
  var result = BigInt.one;
  for (var i = 0; i < digits; i++) {
    result *= BigInt.from(10);
  }
  return result;
}
