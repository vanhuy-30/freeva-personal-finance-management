/// An amount shown in the profile currency next to the original one
/// (BE-P2-013). Display only: the rate is the one the user typed and the
/// stored amount never changes.
class DisplayConverted {
  const DisplayConverted({
    required this.currency,
    required this.minor,
    required this.rate,
    required this.quotedAt,
  });

  final String currency;
  final BigInt minor;

  /// Decimal text, 1 original unit = [rate] [currency].
  final String rate;
  final DateTime quotedAt;

  /// Null when the server sent none; throws [FormatException] on bad data.
  static DisplayConverted? fromJson(Object? value) {
    if (value == null) return null;
    final json = value as Map<String, dynamic>;
    final currency = json['currencyCode'] as String;
    final minor = json['amountMinor'] as String;
    final rate = json['rate'] as String;
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency) ||
        !RegExp(r'^-?[0-9]+$').hasMatch(minor) ||
        !RegExp(r'^\d+(\.\d+)?$').hasMatch(rate)) {
      throw const FormatException();
    }
    return DisplayConverted(
      currency: currency,
      minor: BigInt.parse(minor),
      rate: rate,
      quotedAt: DateTime.parse(json['quotedAt'] as String),
    );
  }
}
