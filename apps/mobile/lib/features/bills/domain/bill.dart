const billAmountKinds = ['fixed', 'estimated'];
const billStatuses = ['open', 'overdue', 'paid'];

class Bill {
  const Bill({
    required this.id,
    required this.clientId,
    required this.name,
    required this.dueOn,
    required this.amountMinor,
    required this.amountKind,
    required this.currencyCode,
    required this.recurringRuleId,
    required this.paidTransactionId,
    required this.paid,
    required this.overdue,
    required this.version,
  });

  final String id;
  final String clientId;
  final String name;
  final String dueOn;
  final BigInt amountMinor;
  final String amountKind;
  final String currencyCode;
  final String? recurringRuleId;
  final String? paidTransactionId;
  final bool paid;
  final bool overdue;
  final int version;

  Bill copyWith({
    String? name,
    String? dueOn,
    BigInt? amountMinor,
    String? amountKind,
    String? currencyCode,
    String? recurringRuleId,
    bool clearRule = false,
    String? paidTransactionId,
    bool clearPaid = false,
    bool? paid,
    bool? overdue,
    int? version,
  }) => Bill(
    id: id,
    clientId: clientId,
    name: name ?? this.name,
    dueOn: dueOn ?? this.dueOn,
    amountMinor: amountMinor ?? this.amountMinor,
    amountKind: amountKind ?? this.amountKind,
    currencyCode: currencyCode ?? this.currencyCode,
    recurringRuleId: clearRule
        ? null
        : (recurringRuleId ?? this.recurringRuleId),
    paidTransactionId: clearPaid
        ? null
        : (paidTransactionId ?? this.paidTransactionId),
    paid: paid ?? this.paid,
    overdue: overdue ?? this.overdue,
    version: version ?? this.version,
  );
}

class BillDraft {
  const BillDraft({
    required this.clientId,
    required this.name,
    required this.dueOn,
    required this.amountMinor,
    required this.amountKind,
    required this.currencyCode,
    required this.recurringRuleId,
  });

  final String clientId;
  final String name;
  final String dueOn;
  final BigInt amountMinor;
  final String amountKind;
  final String currencyCode;
  final String? recurringRuleId;
}
