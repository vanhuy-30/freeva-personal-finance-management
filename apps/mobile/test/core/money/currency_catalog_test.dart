import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/currency_catalog.dart';

void main() {
  group('MOB-P5-001 CurrencyCatalog', () {
    const catalog = CurrencyCatalog([
      CurrencyInfo(code: 'USD', minorDigits: 2),
      CurrencyInfo(code: 'VND', minorDigits: 0, symbol: '₫', isDefault: true),
    ]);

    test('reads digits and symbols from the server list', () {
      expect(catalog.digits('VND'), 0);
      expect(catalog.digits('USD'), 2);
      expect(catalog.symbol('VND'), '₫');
      expect(catalog.symbol('USD'), 'USD');
    });

    test('an unlisted code shows without decimals and as its code', () {
      expect(catalog.digits('JPY'), 0);
      expect(catalog.symbol('JPY'), 'JPY');
    });

    test('the default is the one the server marks, else the first', () {
      expect(catalog.defaultCode, 'VND');
      expect(
        const CurrencyCatalog([CurrencyInfo(code: 'EUR', minorDigits: 2)])
            .defaultCode,
        'EUR',
      );
      expect(const CurrencyCatalog([]).defaultCode, '');
    });

    test('round-trips through JSON', () {
      final info = CurrencyInfo.fromJson(const {
        'code': 'VND',
        'minorDigits': 0,
        'symbol': '₫',
        'isDefault': true,
      });
      expect(info.toJson(), {
        'code': 'VND',
        'minorDigits': 0,
        'symbol': '₫',
        'isDefault': true,
      });
    });
  });
}
