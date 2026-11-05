/// Credit-card installment plans (BE-P3-009 / MOB-P3-009). A plan is only a
/// schedule over one card purchase: no money moves, the purchase stays one
/// expense. Every amount comes from the API; the app only adds them up.
library;

enum InstallmentPeriodState { past, upcoming, closed }

/// One period of a plan (or of a preview, where [state] is upcoming).
class InstallmentPeriod {
  const InstallmentPeriod({
    required this.index,
    required this.dueOn,
    required this.amountMinor,
    this.state = InstallmentPeriodState.upcoming,
  });

  final int index;

  /// `yyyy-MM-dd`.
  final String dueOn;
  final BigInt amountMinor;
  final InstallmentPeriodState state;
}

class CardInstallment {
  const CardInstallment({
    required this.id,
    required this.clientId,
    required this.transactionId,
    required this.accountId,
    required this.currencyCode,
    required this.totalMinor,
    required this.installmentMinor,
    required this.installmentCount,
    required this.firstDueOn,
    required this.active,
    required this.remainingCount,
    required this.nextDueOn,
    required this.nextAmountMinor,
    required this.version,
    this.purchaseOn,
    this.purchaseMerchant,
    this.purchaseCategoryId,
    this.periods,
  });

  final String id;
  final String clientId;

  /// The purchase expense on the card.
  final String transactionId;
  final String accountId;
  final String currencyCode;
  final BigInt totalMinor;
  final BigInt installmentMinor;
  final int installmentCount;
  final String firstDueOn;

  /// False once closed (paid off early or cancelled).
  final bool active;

  /// Periods due today or later; 0 when closed.
  final int remainingCount;
  final String? nextDueOn;
  final BigInt? nextAmountMinor;
  final int version;
  final String? purchaseOn;
  final String? purchaseMerchant;
  final String? purchaseCategoryId;

  /// Full schedule; only on detail, create and close.
  final List<InstallmentPeriod>? periods;

  /// Number of the next period ("Kỳ 2/6"); null when nothing is left.
  int? get nextIndex => active && remainingCount > 0
      ? installmentCount - remainingCount + 1
      : null;

  /// Periods whose day has passed ("Đã trả 1/6 kỳ").
  int get pastCount => installmentCount - remainingCount;

  /// Sum of the periods still ahead; null without the schedule.
  BigInt? get remainingMinor {
    final list = periods;
    if (list == null) return null;
    return list
        .where((p) => p.state == InstallmentPeriodState.upcoming)
        .fold<BigInt>(BigInt.zero, (sum, p) => sum + p.amountMinor);
  }
}

/// What a plan over the purchase would be; nothing is written.
class InstallmentPreview {
  const InstallmentPreview({
    required this.totalMinor,
    required this.installmentMinor,
    required this.installmentCount,
    required this.firstDueOn,
    required this.lastDueOn,
    required this.periods,
  });

  final BigInt totalMinor;
  final BigInt installmentMinor;
  final int installmentCount;
  final String firstDueOn;
  final String lastDueOn;
  final List<InstallmentPeriod> periods;
}

/// Input of a preview or a create. [installmentMinor] null = even split.
class InstallmentDraft {
  const InstallmentDraft({
    required this.transactionId,
    required this.installmentCount,
    required this.firstDueOn,
    this.installmentMinor,
  });

  final String transactionId;
  final int installmentCount;
  final BigInt? installmentMinor;
  final String firstDueOn;

  static const minCount = 2;
  static const maxCount = 60;
}

/// Installments falling due in a range on one card.
class InstallmentDue {
  const InstallmentDue({
    required this.accountId,
    required this.currencyCode,
    required this.dueMinor,
    required this.planCount,
  });

  final String accountId;
  final String currencyCode;
  final BigInt dueMinor;
  final int planCount;
}

/// "Phải trả kỳ này" of a card with plans. The card debt already holds every
/// purchase in full, so the periods due after this due date are taken off;
/// [installmentMinor] is the part of the plans due in this period.
class CardPeriodDue {
  const CardPeriodDue({
    required this.dueOn,
    required this.amountMinor,
    required this.installmentMinor,
  });

  /// From the card debt and the installments due after [dueOn]; never
  /// below zero.
  factory CardPeriodDue.of({
    required DateTime dueOn,
    required BigInt debtMinor,
    required BigInt laterMinor,
    required BigInt installmentMinor,
  }) {
    final left = debtMinor - laterMinor;
    return CardPeriodDue(
      dueOn: dueOn,
      amountMinor: left < BigInt.zero ? BigInt.zero : left,
      installmentMinor: installmentMinor,
    );
  }

  final DateTime dueOn;
  final BigInt amountMinor;
  final BigInt installmentMinor;
}

/// The due day of the period before [due]: same day a month earlier,
/// clamped to the month end like `nextDueDate`.
DateTime previousDueDate(DateTime due, int dueDay) {
  final month = DateTime(due.year, due.month - 1);
  final last = DateTime(month.year, month.month + 1, 0).day;
  return DateTime(month.year, month.month, dueDay > last ? last : dueDay);
}

String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Suggested "Kỳ đầu" for a purchase on [purchaseOn] (`yyyy-MM-dd`): the
/// card's due day after the statement that holds the purchase (closes on
/// [closeDay] on or after the purchase), else the due day after the
/// purchase, else the same day a month later. Never before the purchase.
String suggestedFirstDue(String purchaseOn, {int? closeDay, int? dueDay}) {
  final bought = DateTime(
    int.parse(purchaseOn.substring(0, 4)),
    int.parse(purchaseOn.substring(5, 7)),
    int.parse(purchaseOn.substring(8, 10)),
  );
  DateTime onDay(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  DateTime next(int day, DateTime from) {
    final thisMonth = onDay(from.year, from.month, day);
    return thisMonth.isBefore(from)
        ? onDay(from.year, from.month + 1, day)
        : thisMonth;
  }

  if (dueDay == null || dueDay < 1) {
    return isoDay(onDay(bought.year, bought.month + 1, bought.day));
  }
  final statement = closeDay == null || closeDay < 1
      ? bought
      : next(closeDay, bought);
  return isoDay(next(dueDay, statement.add(const Duration(days: 1))));
}
