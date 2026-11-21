import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/investments/domain/investment.dart';

Investment _deposit({String? maturity, String? start = '2026-02-01'}) =>
    Investment(
      id: 'd',
      clientId: 'd',
      kind: InvestmentKind.savingsDeposit,
      name: 'Quỹ dự phòng',
      currencyCode: 'VND',
      unit: 'deposit',
      quantity: '1',
      costBasisMinor: BigInt.from(60000000),
      currentValueMinor: BigInt.from(60000000),
      valuation: InvestmentValuation.deposit,
      version: 1,
      interestRateBps: 750,
      startDate: start,
      maturityDate: maturity,
    );

void main() {
  group('deposit interest', () {
    test('a year at 7,5% on 60 triệu pays 4,5 triệu at maturity', () {
      final d = _deposit(maturity: '2027-02-01');
      expect(d.interestAtMaturity, BigInt.from(4500000));
    });

    test('accrues to today, and stops at maturity', () {
      final d = _deposit(maturity: '2027-02-01');
      expect(d.interestOn('2026-02-01'), BigInt.zero);
      expect(d.interestOn('2026-08-01'), BigInt.from(2231507));
      expect(d.interestOn('2030-01-01'), BigInt.from(4500000));
    });

    test('no maturity, no payout figure', () {
      expect(_deposit().interestAtMaturity, isNull);
    });
  });

  group('maturedOn', () {
    test('from the maturity day on, while money is still held', () {
      final d = _deposit(maturity: '2026-11-20');
      expect(d.maturedOn('2026-11-19'), isFalse);
      expect(d.maturedOn('2026-11-20'), isTrue);
      expect(d.maturedOn('2027-01-01'), isTrue);
    });

    test('never for a deposit without maturity', () {
      expect(_deposit().maturedOn('2099-01-01'), isFalse);
    });
  });
}
