import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/recurring/domain/recurring_calendar.dart';

void main() {
  group('MOB-P2-E01 recurring calendar', () {
    test('clamps months without day 31', () {
      expect(addInterval('2026-01-31', 'month', 1, 31), '2026-02-28');
      expect(addInterval('2026-02-28', 'month', 1, 31), '2026-03-31');
      expect(addInterval('2024-01-31', 'month', 1, 31), '2024-02-29');
    });

    test('lists due dates and skips inactive', () {
      expect(
        dueDates(
          nextExecutionDate: '2026-01-31',
          startDate: '2026-01-31',
          endDate: '2026-03-31',
          today: '2026-03-15',
          unit: 'month',
          interval: 1,
          active: true,
        ),
        ['2026-01-31', '2026-02-28'],
      );
      expect(
        dueDates(
          nextExecutionDate: '2026-01-01',
          startDate: '2026-01-01',
          endDate: null,
          today: '2026-01-05',
          unit: 'day',
          interval: 1,
          active: false,
        ),
        isEmpty,
      );
    });
  });
}
