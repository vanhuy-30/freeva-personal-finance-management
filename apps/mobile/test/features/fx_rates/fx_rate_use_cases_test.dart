import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/currency_usage.dart';
import 'package:mobile/core/money/display_converted.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/fx_rates/domain/fx_rate_use_cases.dart';

import 'fakes.dart';

void main() {
  test('usesMultipleCurrencies needs two different codes', () {
    expect(usesMultipleCurrencies(const []), isFalse);
    expect(usesMultipleCurrencies(const ['VND', 'VND']), isFalse);
    expect(usesMultipleCurrencies(const ['VND', 'USD']), isTrue);
  });

  group('converted lines (MOB-P3-004)', () {
    final value = DisplayConverted(
      currency: 'VND',
      minor: BigInt.from(308500),
      rate: '25000.00000000',
      quotedAt: DateTime.utc(2026, 10, 30, 2),
    );
    late MemoryFxRates rates;

    setUp(
      () => rates = MemoryFxRates()
        ..wallet['usd'] = value
        ..transaction['t1'] = value,
    );

    test('shown with two currencies, archived wallets included', () async {
      final cases = FxRateUseCases(rates, FxWallets(['VND', 'USD']));
      expect(await cases.walletConverted('usd'), isNotNull);
      expect(await cases.transactionConverted('t1'), isNotNull);
    });

    test('hidden with one currency, rates stay stored', () async {
      final cases = FxRateUseCases(rates, FxWallets(['USD']));
      expect(await cases.walletConverted('usd'), isNull);
      expect(await cases.transactionConverted('t1'), isNull);
      expect(rates.wallet['usd'], isNotNull);
    });

    test('hidden when the wallets cannot be loaded', () async {
      final wallets = FxWallets()
        ..failure = const AuthFailure(AuthError.network);
      final cases = FxRateUseCases(rates, wallets);
      expect(await cases.walletConverted('usd'), isNull);
    });
  });
}
