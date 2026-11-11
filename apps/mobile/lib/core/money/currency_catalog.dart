/// MOB-P5-001: currencies as the server lists them (`GET /profile/options`):
/// minor digits, display symbol and the currency new accounts start in. The
/// app never decides these itself (no `VND ? 0 : 2`, no hardcoded `₫`).
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.minorDigits,
    this.symbol,
    this.isDefault = false,
  });

  final String code;
  final int minorDigits;

  /// Null shows the code.
  final String? symbol;
  final bool isDefault;

  factory CurrencyInfo.fromJson(Map<String, dynamic> json) => CurrencyInfo(
    code: json['code'] as String,
    minorDigits: (json['minorDigits'] as num).toInt(),
    symbol: json['symbol'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Map<String, Object?> toJson() => {
    'code': code,
    'minorDigits': minorDigits,
    'symbol': symbol,
    'isDefault': isDefault,
  };
}

class CurrencyCatalog {
  const CurrencyCatalog(this.items);

  /// App-wide catalog, published by the server config model once loaded
  /// (signed in). Core widgets and helpers read it; tests set it.
  static CurrencyCatalog current = const CurrencyCatalog([]);

  final List<CurrencyInfo> items;

  bool get isEmpty => items.isEmpty;

  CurrencyInfo? find(String? code) {
    for (final item in items) {
      if (item.code == code) return item;
    }
    return null;
  }

  /// Minor digits of [code]. A code the server does not list cannot come
  /// from the ledger; it shows without decimals.
  int digits(String? code) => find(code)?.minorDigits ?? 0;

  /// Display symbol (`₫`), or the code when the server has none.
  String symbol(String code) => find(code)?.symbol ?? code;

  /// The currency new accounts start in; used until the profile loads.
  String get defaultCode {
    for (final item in items) {
      if (item.isDefault) return item.code;
    }
    return items.isEmpty ? '' : items.first.code;
  }
}
