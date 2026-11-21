import '../features/home/fixtures.dart' show wallet;
import '../features/wallets/d1_stub.dart' show StubWalletViewModel;

/// Four wallets that add up to 48.250.000, plus a card the forecast skips.
class ForecastWallets extends StubWalletViewModel {
  ForecastWallets()
    : super(
        wallets: [
          wallet('vcb', 'Vietcombank', balance: 30000000),
          wallet('tcb', 'Techcombank', balance: 10000000),
          wallet('momo', 'MoMo', balance: 5000000),
          wallet('cash', 'Tiền mặt', balance: 3250000),
        ],
      );
}
