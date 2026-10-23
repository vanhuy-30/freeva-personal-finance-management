import 'wallet.dart';

/// Sum of wallet balances in one currency. Never converted between currencies.
class WalletTotal {
  const WalletTotal({
    required this.currency,
    required this.minor,
    required this.count,
  });

  final String currency;
  final BigInt minor;
  final int count;
}

/// Totals of [wallets] per currency, [mainCurrency] first (zero when no wallet
/// uses it and nothing else exists), then the others by code. Credit debt
/// counts as negative, like net worth.
List<WalletTotal> walletTotals(List<Wallet> wallets, String mainCurrency) {
  final sums = <String, BigInt>{};
  final counts = <String, int>{};
  for (final wallet in wallets) {
    final code = wallet.draft.currency;
    sums[code] = (sums[code] ?? BigInt.zero) + wallet.balance;
    counts[code] = (counts[code] ?? 0) + 1;
  }
  final codes = sums.keys.toList()..sort();
  final main = sums.containsKey(mainCurrency)
      ? mainCurrency
      : codes.firstOrNull ?? mainCurrency;
  return [
    WalletTotal(
      currency: main,
      minor: sums[main] ?? BigInt.zero,
      count: counts[main] ?? 0,
    ),
    for (final code in codes)
      if (code != main)
        WalletTotal(currency: code, minor: sums[code]!, count: counts[code]!),
  ];
}
