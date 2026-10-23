import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/onboarding/presentation/viewmodels/setup_wallets_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../auth/setup_deps.dart';

void main() {
  late MemoryWalletRepository api;
  late SetupWalletsViewModel model;
  setUp(() {
    api = MemoryWalletRepository();
    model = SetupWalletsViewModel(DefaultWalletUseCases(api));
  });
  tearDown(() => model.dispose());

  WalletDraft draft(WalletType type, [int balance = 850000]) => WalletDraft(
    name: 'Ví',
    type: type,
    currency: 'VND',
    initialBalance: BigInt.from(balance),
  );

  test(
    'currencies load once; a failed load says so and can be retried',
    () async {
      api.failure = const AuthFailure(AuthError.network);
      expect(await model.ensureCurrencies(), isFalse);
      expect(model.failure?.code, AuthError.network);
      api.failure = null;
      expect(await model.ensureCurrencies(), isTrue);
      expect(model.currencies.map((c) => c.code), ['VND', 'USD']);
    },
  );

  test('one wallet per type: the second of a type is refused', () async {
    await model.ensureCurrencies();
    expect(
      await model.save(draft(WalletType.cash), model.newClientId()),
      isTrue,
    );
    expect(model.added[WalletType.cash]?.balance, BigInt.from(850000));
    expect(
      await model.save(draft(WalletType.cash), model.newClientId()),
      isFalse,
    );
    expect(
      await model.save(draft(WalletType.bank, 0), model.newClientId()),
      isTrue,
    );
    expect(api.saved, hasLength(2));
  });

  test('a failed save keeps the row open and reports why', () async {
    await model.ensureCurrencies();
    api.failure = const AuthFailure(AuthError.network);
    expect(
      await model.save(draft(WalletType.ewallet), model.newClientId()),
      isFalse,
    );
    expect(model.added, isEmpty);
    expect(model.failure?.code, AuthError.network);
  });
}
