import 'report_period.dart';

/// Where the range popup stands: nothing, a start, or a full range.
class RangeSelection {
  const RangeSelection({this.from, this.to});

  final String? from;
  final String? to;

  bool get complete => from != null && to != null;

  /// Days covered, both ends included; null until complete.
  int? get days {
    final apart = complete ? daysApart(from!, to!) : null;
    return apart == null ? null : apart + 1;
  }

  /// First tap sets the start, the second the end (the same day gives a
  /// one-day range). An earlier second tap moves the start instead, and a tap
  /// on a complete range begins a new one.
  RangeSelection tap(String day) {
    final start = from;
    if (start == null || complete) return RangeSelection(from: day);
    if (day.compareTo(start) < 0) return RangeSelection(from: day);
    return RangeSelection(from: start, to: day);
  }

  bool covers(String day) =>
      complete && day.compareTo(from!) >= 0 && day.compareTo(to!) <= 0;
}

enum QuickRange { last7, last30, quarter }

/// Quick picks always end today: the last 7 or 30 days, or the calendar
/// quarter so far.
RangeSelection quickRange(QuickRange kind, String today) {
  switch (kind) {
    case QuickRange.last7:
      return RangeSelection(from: shiftCalendarDate(today, -6), to: today);
    case QuickRange.last30:
      return RangeSelection(from: shiftCalendarDate(today, -29), to: today);
    case QuickRange.quarter:
      final month = int.parse(today.substring(5, 7));
      final first = ((month - 1) ~/ 3) * 3 + 1;
      return RangeSelection(
        from: '${today.substring(0, 5)}${first.toString().padLeft(2, '0')}-01',
        to: today,
      );
  }
}

/// Future days, and days that would make the range longer than the API
/// accepts once a start is chosen, cannot be picked.
bool dayLocked(String day, RangeSelection selection, String today) {
  if (day.compareTo(today) > 0) return true;
  final start = selection.from;
  if (start == null || selection.complete) return false;
  final apart = daysApart(start, day);
  return apart != null && apart > maxReportRangeDays;
}
