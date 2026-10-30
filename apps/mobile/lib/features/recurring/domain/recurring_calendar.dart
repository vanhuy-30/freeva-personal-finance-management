/// Calendar-date math for recurring rules. Dates are YYYY-MM-DD.
library;

const recurringUnits = ['day', 'week', 'month', 'year'];

({int year, int month, int day})? parseCalendarParts(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(5, 7));
  final day = int.parse(value.substring(8, 10));
  final check = DateTime.utc(year, month, day);
  if (check.year != year || check.month != month || check.day != day) {
    return null;
  }
  if (value.compareTo('0001-01-01') < 0) return null;
  return (year: year, month: month, day: day);
}

String formatCalendarParts(int year, int month, int day) =>
    '${year.toString().padLeft(4, '0')}-'
    '${month.toString().padLeft(2, '0')}-'
    '${day.toString().padLeft(2, '0')}';

int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

int anchorDay(String startDate) => parseCalendarParts(startDate)!.day;

/// Advance [from] by [interval] units. Month/year keep [preferredDay] clamped.
String? addInterval(
  String from,
  String unit,
  int interval,
  int preferredDay,
) {
  if (interval < 1 || interval > 366) return null;
  if (preferredDay < 1 || preferredDay > 31) return null;
  final parts = parseCalendarParts(from);
  if (parts == null) return null;
  if (unit == 'day') {
    final date = DateTime.utc(parts.year, parts.month, parts.day + interval);
    return formatCalendarParts(date.year, date.month, date.day);
  }
  if (unit == 'week') {
    return addInterval(from, 'day', 7 * interval, preferredDay);
  }
  if (unit == 'month') {
    final total = parts.year * 12 + (parts.month - 1) + interval;
    final nextYear = total ~/ 12;
    final nextMonth = (total % 12) + 1;
    final nextDay = preferredDay.clamp(1, daysInMonth(nextYear, nextMonth));
    return formatCalendarParts(nextYear, nextMonth, nextDay);
  }
  if (unit == 'year') {
    final nextYear = parts.year + interval;
    final nextDay = preferredDay.clamp(1, daysInMonth(nextYear, parts.month));
    return formatCalendarParts(nextYear, parts.month, nextDay);
  }
  return null;
}

List<String> dueDates({
  required String nextExecutionDate,
  required String startDate,
  required String? endDate,
  required String today,
  required String unit,
  required int interval,
  required bool active,
  int limit = 36,
}) {
  if (!active) return const [];
  if (parseCalendarParts(today) == null) return const [];
  final preferred = anchorDay(startDate);
  final dates = <String>[];
  var cursor = nextExecutionDate;
  for (var i = 0; i < limit; i++) {
    if (cursor.compareTo(today) > 0) break;
    if (endDate != null && cursor.compareTo(endDate) > 0) break;
    dates.add(cursor);
    final next = addInterval(cursor, unit, interval, preferred);
    if (next == null) break;
    cursor = next;
  }
  return dates;
}
