class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.clientId,
    required this.type,
    required this.unit,
    required this.interval,
    required this.amountMinor,
    required this.currencyCode,
    required this.accountId,
    required this.categoryId,
    required this.counterAccountId,
    required this.counterAmountMinor,
    required this.counterCurrencyCode,
    required this.fxRate,
    required this.startDate,
    required this.endDate,
    required this.nextExecutionDate,
    required this.active,
    required this.version,
    this.mode = 'auto',
    this.name,
    this.amountKind = 'fixed',
    required this.remindDaysBefore,
    this.overdue = false,
  });

  final String id;
  final String clientId;
  final String type;
  final String unit;
  final int interval;
  final BigInt amountMinor;
  final String currencyCode;
  final String? accountId;
  final String? categoryId;
  final String? counterAccountId;
  final BigInt? counterAmountMinor;
  final String? counterCurrencyCode;
  final String? fxRate;
  final String startDate;
  final String? endDate;
  final String nextExecutionDate;
  final bool active;
  final int version;

  /// `auto` posts on the due day; `remind` waits for "Đã trả" (a bill).
  final String mode;
  final String? name;

  /// `fixed` or `estimated` (the real amount is entered when confirming).
  final String amountKind;
  final int remindDaysBefore;

  /// Remind rules only: active and the due day is before today.
  final bool overdue;

  bool get isRemind => mode == 'remind';
  bool get isOneOff => endDate != null && endDate == startDate;

  RecurringRule copyWith({
    String? unit,
    int? interval,
    BigInt? amountMinor,
    String? currencyCode,
    String? accountId,
    String? categoryId,
    bool clearCategory = false,
    String? counterAccountId,
    bool clearCounter = false,
    BigInt? counterAmountMinor,
    String? counterCurrencyCode,
    String? fxRate,
    bool clearFx = false,
    String? startDate,
    String? endDate,
    bool clearEnd = false,
    String? nextExecutionDate,
    bool? active,
    int? version,
    String? name,
    String? amountKind,
    int? remindDaysBefore,
  }) => RecurringRule(
    id: id,
    clientId: clientId,
    type: type,
    unit: unit ?? this.unit,
    interval: interval ?? this.interval,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    accountId: accountId ?? this.accountId,
    categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    counterAccountId: clearCounter
        ? null
        : (counterAccountId ?? this.counterAccountId),
    counterAmountMinor: clearCounter
        ? null
        : (counterAmountMinor ?? this.counterAmountMinor),
    counterCurrencyCode: clearCounter
        ? null
        : (counterCurrencyCode ?? this.counterCurrencyCode),
    fxRate: clearFx ? null : (fxRate ?? this.fxRate),
    startDate: startDate ?? this.startDate,
    endDate: clearEnd ? null : (endDate ?? this.endDate),
    nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
    active: active ?? this.active,
    version: version ?? this.version,
    mode: mode,
    name: name ?? this.name,
    amountKind: amountKind ?? this.amountKind,
    remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    overdue: overdue,
  );
}

class RecurringDraft {
  const RecurringDraft({
    required this.clientId,
    required this.type,
    required this.unit,
    required this.interval,
    required this.amountMinor,
    required this.currencyCode,
    required this.accountId,
    required this.categoryId,
    required this.counterAccountId,
    required this.counterAmountMinor,
    required this.counterCurrencyCode,
    required this.fxRate,
    required this.startDate,
    required this.endDate,
    required this.nextExecutionDate,
    required this.active,
    this.mode = 'auto',
    this.name,
    this.amountKind = 'fixed',
    required this.remindDaysBefore,
    this.repeat = true,
  });

  final String clientId;
  final String type;
  final String unit;
  final int interval;
  final BigInt amountMinor;
  final String currencyCode;
  final String? accountId;
  final String? categoryId;
  final String? counterAccountId;
  final BigInt? counterAmountMinor;
  final String? counterCurrencyCode;
  final String? fxRate;
  final String startDate;
  final String? endDate;
  final String nextExecutionDate;
  final bool active;
  final String mode;
  final String? name;
  final String amountKind;
  final int remindDaysBefore;

  /// false makes a one-off bill (the API sets endDate = startDate).
  final bool repeat;
}

class RecurringRunResult {
  const RecurringRunResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}

/// "Đã trả" for one due day of a remind rule. Either [transactionId] links an
/// expense that already exists, or the API posts one from the other fields.
class RecurringConfirm {
  const RecurringConfirm({
    required this.occurredOn,
    this.transactionId,
    this.accountId,
    this.amountMinor,
    this.paidOn,
  });

  /// The due day being confirmed (the rule's `nextExecutionDate`).
  final String occurredOn;
  final String? transactionId;
  final String? accountId;

  /// Positive magnitude of what was really paid.
  final BigInt? amountMinor;
  final String? paidOn;
}

class RecurringConfirmResult {
  const RecurringConfirmResult({
    required this.rule,
    required this.transactionId,
    required this.replayed,
  });

  final RecurringRule rule;
  final String transactionId;
  final bool replayed;
}
