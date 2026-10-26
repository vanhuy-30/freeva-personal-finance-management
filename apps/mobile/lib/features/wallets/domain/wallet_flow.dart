import '../../transactions/domain/transaction.dart';

/// Money in and out of one wallet over a period, as positive magnitudes.
/// Transfers count: moving money into the wallet is money in.
class WalletFlow {
  const WalletFlow({required this.moneyIn, required this.moneyOut});

  /// From a one-wallet summary. A wallet has one currency, so any row is it.
  factory WalletFlow.fromTotals(List<TransactionTotal> totals) {
    var moneyIn = BigInt.zero;
    var moneyOut = BigInt.zero;
    for (final t in totals) {
      moneyIn += t.income + t.transferIn;
      moneyOut -= t.expense + t.transferOut;
    }
    return WalletFlow(moneyIn: moneyIn, moneyOut: moneyOut);
  }

  final BigInt moneyIn;
  final BigInt moneyOut;
}
