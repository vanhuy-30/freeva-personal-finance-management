import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/quantity.dart';

void main() {
  test('parses up to 8 decimals and refuses more', () {
    expect(parseQuantity('3', 'vi'), BigInt.from(300000000));
    expect(parseQuantity('0,12345678', 'vi'), BigInt.from(12345678));
    expect(parseQuantity('0,123456789', 'vi'), isNull);
    expect(parseQuantity('abc', 'vi'), isNull);
    expect(parseQuantity('1.5', 'en'), BigInt.from(150000000));
  });

  test('formats without trailing zeros', () {
    expect(formatQuantity(BigInt.from(300000000), 'vi'), '3');
    expect(formatQuantity(BigInt.from(50000000), 'vi'), '0,5');
    expect(formatQuantity(BigInt.from(12345678), 'vi'), '0,12345678');
    expect(formatQuantity(BigInt.from(250000000), 'en'), '2.5');
  });

  test('api text always uses a dot', () {
    expect(quantityToApi(BigInt.from(300000000)), '3');
    expect(quantityToApi(BigInt.from(12345678)), '0.12345678');
    expect(quantityToApi(BigInt.from(250000000)), '2.5');
    expect(quantityToApi(BigInt.zero), '0');
  });

  test('total rounds half up in integer arithmetic', () {
    // 3 chỉ × 7.200.000.
    expect(
      quantityTotalMinor(BigInt.from(300000000), BigInt.from(7200000)),
      BigInt.from(21600000),
    );
    // 0,12345678 BTC × 1.000.000.000 = 123.456.780.
    expect(
      quantityTotalMinor(BigInt.from(12345678), BigInt.from(1000000000)),
      BigInt.from(123456780),
    );
    // 0,5 × 3 = 1,5 → 2 (half up).
    expect(
      quantityTotalMinor(BigInt.from(50000000), BigInt.from(3)),
      BigInt.two,
    );
    // 0,00000001 × 49 = 0,49 → 0.
    expect(quantityTotalMinor(BigInt.one, BigInt.from(49)), BigInt.zero);
  });
}
