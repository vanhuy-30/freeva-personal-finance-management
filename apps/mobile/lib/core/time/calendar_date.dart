import 'package:timezone/timezone.dart' as tz;

final RegExp _clockTime = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

/// Calendar date `YYYY-MM-DD` in an IANA zone. Returns null when the zone
/// is unknown or timezone data has not been initialized.
String? calendarDate(DateTime instant, String timeZone) {
  try {
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(timeZone));
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  } catch (_) {
    return null;
  }
}

/// Local clock `HH:mm` in an IANA zone. Null when the zone is unknown.
String? clockTime(DateTime instant, String timeZone) {
  try {
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(timeZone));
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  } catch (_) {
    return null;
  }
}

/// True for a real calendar date in years 0001–9999, including leap days.
bool isCalendarDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  if (value.compareTo('0001-01-01') < 0 || value.compareTo('9999-12-31') > 0) {
    return false;
  }
  final parts = value.split('-');
  final date = DateTime.utc(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day' == value;
}

/// True for a 24h clock `HH:mm`.
bool isClockTime(String value) => _clockTime.hasMatch(value);
