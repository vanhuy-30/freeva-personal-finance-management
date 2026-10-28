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
  });

  final String id;
  final String clientId;
  final String type;
  final String unit;
  final int interval;
  final BigInt amountMinor;
  final String currencyCode;
  final String accountId;
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
  });

  final String clientId;
  final String type;
  final String unit;
  final int interval;
  final BigInt amountMinor;
  final String currencyCode;
  final String accountId;
  final String? categoryId;
  final String? counterAccountId;
  final BigInt? counterAmountMinor;
  final String? counterCurrencyCode;
  final String? fxRate;
  final String startDate;
  final String? endDate;
  final String nextExecutionDate;
  final bool active;
}

class RecurringRunResult {
  const RecurringRunResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}
