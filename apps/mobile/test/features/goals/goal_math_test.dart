import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/goals/domain/goal_math.dart';

void main() {
  group('MOB-P3-E01 goal formulas', () {
    test('target 120 000 000, saved 40 000 000, 10 months → 8 000 000', () {
      expect(
        goalRequiredPerMonth(BigInt.from(120000000), BigInt.from(40000000), 10),
        BigInt.from(8000000),
      );
    });

    test('rounds up, zero when reached, null without a future date', () {
      expect(
        goalRequiredPerMonth(BigInt.from(100), BigInt.zero, 3),
        BigInt.from(34),
      );
      expect(
        goalRequiredPerMonth(BigInt.from(100), BigInt.from(100), 3),
        BigInt.zero,
      );
      expect(goalRequiredPerMonth(BigInt.from(100), BigInt.zero, null), isNull);
      expect(goalRequiredPerMonth(BigInt.from(100), BigInt.zero, 0), isNull);
    });

    test('a started month counts as a full one, the past gives 0', () {
      expect(goalMonthsLeft('2026-11-02', '2026-12-02'), 1);
      expect(goalMonthsLeft('2026-11-02', '2026-12-03'), 2);
      expect(goalMonthsLeft('2026-11-02', '2026-11-02'), 0);
      expect(goalMonthsLeft('2026-11-02', '2026-09-30'), 0);
    });

    test('income share is in basis points and hidden without income', () {
      expect(
        goalIncomeShareBps(BigInt.from(8000000), BigInt.from(25000000)),
        3200,
      );
      expect(goalIncomeShareBps(BigInt.from(8000000), null), isNull);
      expect(goalIncomeShareBps(null, BigInt.from(25000000)), isNull);
    });
  });
}
