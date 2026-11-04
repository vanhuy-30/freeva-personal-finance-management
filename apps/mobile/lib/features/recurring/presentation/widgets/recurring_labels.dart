import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../categories/domain/finance_category.dart';
import '../../domain/recurring_calendar.dart';
import '../../domain/recurring_rule.dart';

/// `yyyy-MM-dd` as `dd/MM`.
String dayMonth(String date) =>
    '${date.substring(8, 10)}/${date.substring(5, 7)}';

/// Whole days from [today] to [date] (negative once past). Both `yyyy-MM-dd`.
int daysBetween(String today, String date) {
  final a = parseCalendarParts(today);
  final b = parseCalendarParts(date);
  if (a == null || b == null) return 0;
  return DateTime.utc(
    b.year,
    b.month,
    b.day,
  ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
}

/// What a row calls the rule: its name, else its category, else its type.
String ruleTitle(S s, RecurringRule rule, FinanceCategory? category) {
  final name = rule.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (category != null) return category.name;
  return switch (rule.type) {
    'income' => s.recurringTypeIncome,
    'transfer' => s.recurringTypeTransfer,
    _ => s.recurringTypeExpense,
  };
}

/// "Ngày 5 hằng tháng", "Hằng tuần", "Mỗi 2 tháng".
String scheduleLabel(S s, RecurringRule rule) {
  if (rule.isOneOff) return s.recOnce;
  final every = rule.interval;
  if (every == 1) {
    return switch (rule.unit) {
      'day' => s.recEveryDay,
      'week' => s.recEveryWeek,
      'month' => s.recDayOfMonth(anchorDay(rule.startDate).toString()),
      _ => s.recEveryYear,
    };
  }
  final count = every.toString();
  return switch (rule.unit) {
    'day' => s.recEveryNDays(count),
    'week' => s.recEveryNWeeks(count),
    'month' => s.recEveryNMonths(count),
    _ => s.recEveryNYears(count),
  };
}

/// The repeat field value ("Hằng tháng") without the day.
String repeatLabel(
  S s, {
  required bool once,
  required String unit,
  required int interval,
}) {
  if (once) return s.recOnce;
  if (interval == 1) {
    return switch (unit) {
      'day' => s.recEveryDay,
      'week' => s.recEveryWeek,
      'month' => s.recEveryMonth,
      _ => s.recEveryYear,
    };
  }
  final count = interval.toString();
  return switch (unit) {
    'day' => s.recEveryNDays(count),
    'week' => s.recEveryNWeeks(count),
    'month' => s.recEveryNMonths(count),
    _ => s.recEveryNYears(count),
  };
}

/// Second line of a bill: "Hạn 05/11 · khoảng 850.000" (one-off adds
/// "một lần"). [currency] is appended only when it is not the main one.
String dueLine(
  S s,
  RecurringRule rule, {
  required int digits,
  required String locale,
  String? currency,
}) {
  final amount = formatMoneyText(rule.amountMinor.abs(), digits, locale);
  final shown = currency == null ? amount : '$amount $currency';
  return [
    s.recDueOn(dayMonth(rule.nextExecutionDate)),
    if (rule.isOneOff) s.recOneOff,
    rule.amountKind == 'estimated' ? s.recAbout(shown) : shown,
  ].join(' · ');
}
