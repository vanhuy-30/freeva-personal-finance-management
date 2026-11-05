import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_month.dart';
import 'package:mobile/features/calendar/domain/calendar_repository.dart';
import 'package:mobile/features/calendar/domain/calendar_use_cases.dart';

class _FakeRepo implements CalendarRepository {
  String? lastMonth;

  @override
  Future<Either<AuthFailure, CalendarMonth>> month(String month) async {
    lastMonth = month;
    return right(
      CalendarMonth(
        month: month,
        timezone: 'Asia/Ho_Chi_Minh',
        today: '$month-15',
        days: const [],
      ),
    );
  }
}

void main() {
  test('rejects invalid month shapes', () async {
    final cases = DefaultCalendarUseCases(_FakeRepo());
    expect(
      (await cases.month('2026-13')).fold((e) => e.code, (_) => null),
      AuthError.invalidInput,
    );
    expect(
      (await cases.month('2026-10-01')).fold((e) => e.code, (_) => null),
      AuthError.invalidInput,
    );
  });

  test('forwards a valid month to the repository', () async {
    final repo = _FakeRepo();
    final cases = DefaultCalendarUseCases(repo);
    final result = await cases.month('2026-10');
    expect(result.isRight(), isTrue);
    expect(repo.lastMonth, '2026-10');
  });
}
