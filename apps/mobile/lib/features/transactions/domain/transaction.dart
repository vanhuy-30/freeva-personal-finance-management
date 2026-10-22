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
    required this.merchant,
    required this.tagIds,
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
  final String? merchant;
  final List<String> tagIds;
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
  String? get merchant => legs.first.merchant;
  List<String> get tagIds => legs.first.tagIds;
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
    this.merchant,
    this.tagIds = const [],
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
  final String? merchant;
  final List<String> tagIds;
  final String? rate;
  final String? quotedAt;
}

class TransactionCommand {
  const TransactionCommand({
    required this.type,
    required this.occurredOn,
    required this.categoryId,
    required this.notes,
    required this.merchant,
    required this.tagIds,
    required this.legs,
    this.rate,
    this.quotedAt,
    this.version,
  });
  final TransactionType type;
  final String occurredOn;
  final String? categoryId;
  final String? notes;
  final String? merchant;
  final List<String> tagIds;
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
    this.pageSize = 50,
    this.from,
    this.to,
    this.accountIds = const [],
    this.categoryIds = const [],
    this.tagIds = const [],
  });
  final int page;
  final int pageSize;
  final bool deleted;
  final TransactionType? type;
  final String? search;

  /// Inclusive calendar dates `yyyy-MM-dd`.
  final String? from;
  final String? to;

  /// Match any of the listed wallets / categories / tags.
  final List<String> accountIds;
  final List<String> categoryIds;
  final List<String> tagIds;

  TransactionQuery copyWith({
    int? page,
    int? pageSize,
    bool? deleted,
    String? search,
  }) => TransactionQuery(
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    deleted: deleted ?? this.deleted,
    type: type,
    search: search ?? this.search,
    from: from,
    to: to,
    accountIds: accountIds,
    categoryIds: categoryIds,
    tagIds: tagIds,
  );
}

class TransactionTotal {
  const TransactionTotal({
    required this.currency,
    required this.income,
    required this.expense,
  });
  final String currency;
  final BigInt income;

  /// Signed: negative or zero.
  final BigInt expense;
}

/// Totals over the whole filtered result. A transfer counts once and is not
/// income or expense.
class TransactionSummary {
  const TransactionSummary({required this.count, required this.totals});
  static const empty = TransactionSummary(count: 0, totals: []);
  final int count;
  final List<TransactionTotal> totals;
}

class TransactionListPage {
  const TransactionListPage({
    required this.legs,
    required this.page,
    required this.total,
    this.summary = TransactionSummary.empty,
  });
  final List<TxLeg> legs;
  final int page;
  final int total;
  final TransactionSummary summary;
}

/// Pairs the two legs of a transfer into one bundle, keeping list order.
List<TransactionBundle> groupTransactionLegs(List<TxLeg> legs) {
  final grouped = <String, List<TxLeg>>{};
  final order = <String>[];
  for (final leg in legs) {
    final key = leg.transferGroupId ?? leg.id;
    if (!grouped.containsKey(key)) order.add(key);
    grouped.putIfAbsent(key, () => []).add(leg);
  }
  return [
    for (final key in order)
      TransactionBundle(
        legs: List.unmodifiable(
          [...grouped[key]!]..sort((a, b) {
            final amount = a.amountMinor.compareTo(b.amountMinor);
            return amount != 0 ? amount : a.id.compareTo(b.id);
          }),
        ),
      ),
  ];
}
