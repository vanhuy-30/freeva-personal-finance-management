enum TransactionType {
  income,
  expense,
  transfer,

  /// One-leg balance fix from wallet reconcile; not income or expense.
  adjustment,

  /// One-leg money move of a debt (lend, borrow, repay, loan principal); not
  /// income or expense. Only `/personal-debts` and `/loans` write it; the API
  /// refuses edits.
  debt,

  /// Money back for an expense (`MOB-P3-008`): one positive leg pointing at
  /// the expense (`refundOfId`); not income. Only `POST …/refunds` writes it.
  refund,

  /// One-leg money move between a wallet and an investment (buy takes money
  /// out, sell or withdraw puts it back); not income or expense. Only
  /// `/investments` writes it; the API refuses edits and deletes.
  investment,
}

/// What happens to refunds when their expense is deleted (`MOB-P3-008`).
enum RefundDisposition {
  /// Delete the refunds too; the wallets lose that money.
  cascade,

  /// Turn the refunds into plain income.
  keep,
}

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
    this.occurredTime,
    this.refundOfId,
    this.refundedMinor,
    this.installmentPlanId,
  });
  final String id;
  final String clientId;
  final String accountId;
  final String currencyCode;
  final BigInt amountMinor;
  final TransactionType type;
  final String occurredOn;

  /// Optional local clock `HH:mm` in the profile timezone (`MOB-P2-E09`).
  final String? occurredTime;
  final String? categoryId;
  final String? notes;
  final String? merchant;
  final List<String> tagIds;
  final String? transferGroupId;
  final DateTime? deletedAt;
  final int version;
  final DateTime createdAt;

  /// Only on `refund`: the expense it returns money for.
  final String? refundOfId;

  /// Only on `expense` from list/detail reads: active refunds so far (≥ 0).
  final BigInt? refundedMinor;

  /// Only on `expense` from list/detail reads: its card installment plan
  /// (active or closed), null when none (`MOB-P3-009`).
  final String? installmentPlanId;
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
  String? get occurredTime => legs.first.occurredTime;
  String? get categoryId => legs.first.categoryId;
  String? get notes => legs.first.notes;
  String? get merchant => legs.first.merchant;
  List<String> get tagIds => legs.first.tagIds;
  String? get refundOfId => legs.first.refundOfId;

  /// Refunds already made on this expense, zero when none or unknown.
  BigInt get refunded => legs.first.refundedMinor ?? BigInt.zero;

  /// Card installment plan over this expense, if any.
  String? get installmentPlanId => legs.first.installmentPlanId;

  /// What can still be refunded: the expense amount minus refunds so far.
  BigInt get refundable {
    if (type != TransactionType.expense || deleted) return BigInt.zero;
    final left = legs.first.amountMinor.abs() - refunded;
    return left > BigInt.zero ? left : BigInt.zero;
  }
}

/// Input of `POST /transactions/{id}/refunds`.
class RefundCommand {
  const RefundCommand({
    required this.clientId,
    required this.accountId,
    required this.amountMinor,
    required this.occurredOn,
  });
  final String clientId;
  final String accountId;
  final BigInt amountMinor;
  final String occurredOn;
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
    this.occurredTime,
  });
  final TransactionType type;
  final String occurredOn;
  final String? occurredTime;
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
    this.occurredTime,
  });
  final TransactionType type;
  final String occurredOn;
  final String? occurredTime;
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

/// `date` is newest first; `amountDesc` the largest amount first, ignoring sign.
enum TransactionSort { date, amountDesc }

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
    this.sort = TransactionSort.date,
    this.currency,
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
  final TransactionSort sort;

  /// ISO code of the transaction currency.
  final String? currency;

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
    sort: sort,
    currency: currency,
  );
}

class TransactionTotal {
  TransactionTotal({
    required this.currency,
    required this.income,
    required this.expense,
    BigInt? transferIn,
    BigInt? transferOut,
  }) : transferIn = transferIn ?? BigInt.zero,
       transferOut = transferOut ?? BigInt.zero;
  final String currency;
  final BigInt income;

  /// Signed: negative or zero.
  final BigInt expense;

  /// Matching transfer legs that add money (≥ 0). With a one-wallet filter:
  /// money moved into that wallet.
  final BigInt transferIn;

  /// Matching transfer legs that take money (≤ 0).
  final BigInt transferOut;
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
