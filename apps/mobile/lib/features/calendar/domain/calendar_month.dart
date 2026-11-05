class CalendarMonth {
  const CalendarMonth({
    required this.month,
    required this.timezone,
    required this.today,
    required this.days,
  });

  final String month;
  final String timezone;
  final String today;
  final List<CalendarDay> days;

  CalendarDay? dayOn(String date) {
    for (final day in days) {
      if (day.date == date) return day;
    }
    return null;
  }

  bool hasItemsOn(String date) => dayOn(date) != null;
}

class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.transactions,
    required this.recurring,
    required this.bills,
  });

  final String date;
  final List<CalendarTransactionItem> transactions;
  final List<CalendarRecurringItem> recurring;
  final List<CalendarBillItem> bills;

  bool get hasTransactions => transactions.isNotEmpty;
  bool get hasRecurring => recurring.isNotEmpty;
  bool get hasBills => bills.isNotEmpty;
}

class CalendarTransactionItem {
  const CalendarTransactionItem({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryName,
  });

  final String id;
  final String type;
  final BigInt amountMinor;
  final String currencyCode;
  final String? categoryName;
}

class CalendarRecurringItem {
  const CalendarRecurringItem({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryName,
    required this.occurredOn,
  });

  final String id;
  final String type;
  final BigInt amountMinor;
  final String currencyCode;
  final String? categoryName;
  final String occurredOn;
}

class CalendarBillItem {
  const CalendarBillItem({
    required this.id,
    required this.name,
    required this.dueOn,
    required this.amountMinor,
    required this.amountKind,
    required this.currencyCode,
    required this.paid,
    required this.overdue,
  });

  final String id;
  final String name;
  final String dueOn;
  final BigInt amountMinor;
  final String amountKind;
  final String currencyCode;
  final bool paid;
  final bool overdue;
}
