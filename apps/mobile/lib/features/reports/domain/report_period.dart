import '../../auth/domain/auth_repository.dart';
import 'report.dart';

const maxReportRangeDays = 3660;

bool isCalendarDate(String value) => _utc(value) != null;

/// Calendar-day distance from [from] to [to]. Negative when [from] is later.
int? daysApart(String from, String to) {
  final start = _utc(from);
  final end = _utc(to);
  if (start == null || end == null) return null;
  return end.difference(start).inDays;
}

String? shiftCalendarDate(String value, int days) {
  final date = _utc(value);
  if (date == null) return null;
  final next = date.add(Duration(days: days));
  if (next.year < 1 || next.year > 9999) return null;
  return _format(next);
}

AuthFailure? invalidPeriod(ReportPeriodQuery query) {
  if (query.kind == ReportPeriodKind.range) {
    final from = query.from;
    final to = query.to;
    final apart = from == null || to == null ? null : daysApart(from, to);
    if (apart == null || apart < 0 || apart > maxReportRangeDays) {
      return const AuthFailure(AuthError.invalidInput);
    }
    return null;
  }
  if (query.from != null || query.to != null) {
    return const AuthFailure(AuthError.invalidInput);
  }
  if (query.on != null && !isCalendarDate(query.on!)) {
    return const AuthFailure(AuthError.invalidInput);
  }
  return null;
}

/// Steps a week or month by the inclusive bounds the server already resolved.
/// Month length follows the user's fiscal start, so the client only moves the
/// anchor to the day before [ReportPeriod.from] or the day after [ReportPeriod.to].
ReportPeriodQuery? adjacentPeriod(ReportPeriod period, int direction) {
  if (direction != -1 && direction != 1) return null;
  if (period.kind == ReportPeriodKind.range) return null;
  final anchor = direction < 0 ? period.from : period.to;
  final on = shiftCalendarDate(anchor, direction);
  if (on == null) return null;
  return period.kind == ReportPeriodKind.week
      ? ReportPeriodQuery.week(on: on)
      : ReportPeriodQuery.month(on: on);
}

DateTime? _utc(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (year < 1 || year > 9999) return null;
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

String _format(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
