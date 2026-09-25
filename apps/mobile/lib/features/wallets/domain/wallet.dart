enum WalletType { cash, bank, ewallet, credit }

class WalletCurrency {
  const WalletCurrency(this.code, this.minorDigits);
  final String code;
  final int minorDigits;
}

class WalletDraft {
  const WalletDraft({
    required this.name,
    required this.type,
    required this.currency,
    required this.initialBalance,
    this.creditLimit,
    this.closeDay,
    this.dueDay,
  });
  final String name;
  final WalletType type;
  final String currency;
  final BigInt initialBalance;
  final BigInt? creditLimit;
  final int? closeDay;
  final int? dueDay;
}

class Wallet {
  const Wallet({
    required this.id,
    required this.createdAt,
    required this.draft,
    required this.balance,
    required this.version,
    required this.sortOrder,
    required this.archived,
  });
  final String id;
  final DateTime createdAt;
  final WalletDraft draft;
  final BigInt balance;
  final int version;
  final int sortOrder;
  final bool archived;
}
