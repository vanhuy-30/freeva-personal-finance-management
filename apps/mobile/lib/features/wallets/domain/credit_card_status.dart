import 'wallet.dart';

enum CreditLevel { normal, high, critical }

/// A credit wallet read as a card: debt, limit and next due date.
class CreditCardStatus {
  const CreditCardStatus({
    required this.wallet,
    required this.used,
    required this.limit,
    required this.nextDue,
  });

  /// Used = debt (the negative part of the balance), due date from dueDay.
  factory CreditCardStatus.of(Wallet wallet, DateTime today) =>
      CreditCardStatus(
        wallet: wallet,
        used: wallet.balance < BigInt.zero ? -wallet.balance : BigInt.zero,
        limit: wallet.draft.creditLimit,
        nextDue: nextDueDate(wallet.draft.dueDay, today),
      );

  final Wallet wallet;
  final BigInt used;
  final BigInt? limit;
  final DateTime? nextDue;

  /// What is left of the limit, never below zero; null without a limit.
  BigInt? get available {
    final cap = limit;
    if (cap == null) return null;
    final left = cap - used;
    return left < BigInt.zero ? BigInt.zero : left;
  }

  /// 0–1 of the limit; 0 when there is no limit.
  double get ratio {
    final cap = limit;
    if (cap == null || cap <= BigInt.zero) return 0;
    final value = used * BigInt.from(10000) ~/ cap;
    return (value.toInt() / 10000).clamp(0, 1).toDouble();
  }

  /// < 70% normal, 70–90% high, > 90% critical.
  CreditLevel get level => ratio > .9
      ? CreditLevel.critical
      : ratio >= .7
      ? CreditLevel.high
      : CreditLevel.normal;

  /// Calendar days from [today] to the next due date; null without one.
  int? daysUntilDue(DateTime today) {
    final due = nextDue;
    if (due == null) return null;
    final from = DateTime.utc(today.year, today.month, today.day);
    return DateTime.utc(due.year, due.month, due.day).difference(from).inDays;
  }

  bool dueWithin(DateTime today, int days) {
    final left = daysUntilDue(today);
    return left != null && left >= 0 && left <= days;
  }
}

/// Next occurrence of [dueDay] on or after [today]; clamps to month end.
DateTime? nextDueDate(int? dueDay, DateTime today) {
  if (dueDay == null || dueDay < 1) return null;
  DateTime on(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dueDay > last ? last : dueDay);
  }

  final day = DateTime(today.year, today.month, today.day);
  final thisMonth = on(today.year, today.month);
  return thisMonth.isBefore(day) ? on(today.year, today.month + 1) : thisMonth;
}
