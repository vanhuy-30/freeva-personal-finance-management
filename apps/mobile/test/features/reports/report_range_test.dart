import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/reports/domain/report_period.dart';
import 'package:mobile/features/reports/domain/report_range.dart';

void main() {
  const today = '2026-10-21';

  group('RangeSelection.tap', () {
    test('first tap starts, second ends, third starts again', () {
      var pick = const RangeSelection().tap('2026-10-06');
      expect(pick.from, '2026-10-06');
      expect(pick.complete, isFalse);
      pick = pick.tap('2026-10-19');
      expect(pick.complete, isTrue);
      expect(pick.days, 14);
      pick = pick.tap('2026-10-02');
      expect(pick.from, '2026-10-02');
      expect(pick.to, isNull);
    });

    test('the same day is a one-day range; an earlier day moves the start', () {
      final one = const RangeSelection().tap('2026-10-06').tap('2026-10-06');
      expect(one.days, 1);
      final moved = const RangeSelection(from: '2026-10-06').tap('2026-10-01');
      expect(moved.from, '2026-10-01');
      expect(moved.complete, isFalse);
    });

    test('counts leap days and covers both ends', () {
      const pick = RangeSelection(from: '2024-02-28', to: '2024-03-01');
      expect(pick.days, 3);
      expect(pick.covers('2024-02-29'), isTrue);
      expect(pick.covers('2024-03-02'), isFalse);
      expect(const RangeSelection(from: '2026-10-01').days, isNull);
    });
  });

  group('quick picks end today', () {
    test('7 and 30 days include today', () {
      expect(quickRange(QuickRange.last7, today).from, '2026-10-15');
      expect(quickRange(QuickRange.last7, today).days, 7);
      expect(quickRange(QuickRange.last30, today).from, '2026-09-22');
      expect(quickRange(QuickRange.last30, '2026-03-05').from, '2026-02-04');
      expect(quickRange(QuickRange.last30, today).to, today);
    });

    test(
      'the quarter starts on the calendar quarter, not the fiscal month',
      () {
        expect(quickRange(QuickRange.quarter, today).from, '2026-10-01');
        expect(quickRange(QuickRange.quarter, '2026-02-10').from, '2026-01-01');
        expect(quickRange(QuickRange.quarter, '2026-06-30').from, '2026-04-01');
        expect(quickRange(QuickRange.quarter, '2026-09-01').from, '2026-07-01');
      },
    );
  });

  group('dayLocked', () {
    test('future days are locked', () {
      expect(dayLocked('2026-10-22', const RangeSelection(), today), isTrue);
      expect(dayLocked(today, const RangeSelection(), today), isFalse);
    });

    test('a start limits the end to 3660 days', () {
      const from = '2016-10-20';
      final edge = shiftCalendarDate(from, maxReportRangeDays)!;
      final past = shiftCalendarDate(from, maxReportRangeDays + 1)!;
      const start = RangeSelection(from: from);
      expect(dayLocked(edge, start, '2026-12-31'), isFalse);
      expect(dayLocked(past, start, '2026-12-31'), isTrue);
      // Once the range is complete a new tap restarts it, so nothing is limited.
      final full = RangeSelection(from: from, to: edge);
      expect(dayLocked(past, full, '2026-12-31'), isFalse);
    });
  });
}
