enum TransactionType { income, expense, transfer }

class TxLeg {
  const TxLeg({
    required this.id,
    required this.clientId,
    required this.accountId,
    required this.currencyCode,
    required this.amountMinor,
    required this.type,
    required this.occurredOn,
    required this.categoryId,
    required this.notes,
    required this.transferGroupId,
    required this.deletedAt,
    required this.version,
    required this.createdAt,
  });
  final String id;
  final String clientId;
  final String accountId;
  final String currencyCode;
  final BigInt amountMinor;
  final TransactionType type;
  final String occurredOn;
  final String? categoryId;
  final String? notes;
  final String? transferGroupId;
  final DateTime? deletedAt;
  final int version;
  final DateTime createdAt;
}

class TransactionFx {
  const TransactionFx({required this.rate, required this.quotedAt});
  final String rate;
  final String quotedAt;
}

class TransactionBundle {
  const TransactionBundle({required this.legs, this.fx});
  final List<TxLeg> legs;
  final TransactionFx? fx;
  TransactionType get type => legs.first.type;
  int get version => legs.first.version;
  bool get deleted => legs.first.deletedAt != null;
  String get id => legs.first.id;
  String get occurredOn => legs.first.occurredOn;
  String? get categoryId => legs.first.categoryId;
  String? get notes => legs.first.notes;
}

class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.occurredOn,
    required this.accountId,
    required this.magnitude,
    required this.clientIds,
    this.counterAccountId,
    this.categoryId,
    this.notes,
    this.rate,
    this.quotedAt,
  });
  final TransactionType type;
  final String occurredOn;
  final String accountId;
  final String? counterAccountId;
  final BigInt magnitude;
  final List<String> clientIds;
  final String? categoryId;
  final String? notes;
  final String? rate;
  final String? quotedAt;
}

class TransactionCommand {
  const TransactionCommand({
    required this.type,
    required this.occurredOn,
    required this.categoryId,
    required this.notes,
    required this.legs,
    this.rate,
    this.quotedAt,
    this.version,
  });
  final TransactionType type;
  final String occurredOn;
  final String? categoryId;
  final String? notes;
  final List<TransactionLegCommand> legs;
  final String? rate;
  final String? quotedAt;
  final int? version;
}

class TransactionLegCommand {
  const TransactionLegCommand({
    required this.clientId,
    required this.accountId,
    required this.currencyCode,
    required this.amountMinor,
  });
  final String clientId;
  final String accountId;
  final String currencyCode;
  final BigInt amountMinor;
}

class TransactionQuery {
  const TransactionQuery({
    this.page = 1,
    this.deleted = false,
    this.type,
    this.search,
  });
  final int page;
  final bool deleted;
  final TransactionType? type;
  final String? search;
}

class TransactionListPage {
  const TransactionListPage({
    required this.legs,
    required this.page,
    required this.total,
  });
  final List<TxLeg> legs;
  final int page;
  final int total;
}
