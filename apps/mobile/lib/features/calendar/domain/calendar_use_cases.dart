import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'calendar_month.dart';
import 'calendar_repository.dart';

abstract class CalendarUseCases {
  Future<Either<AuthFailure, CalendarMonth>> month(String month);
}

@LazySingleton(as: CalendarUseCases)
class DefaultCalendarUseCases implements CalendarUseCases {
  DefaultCalendarUseCases(this._repository);
  final CalendarRepository _repository;

  static final _month = RegExp(r'^\d{4}-\d{2}$');

  @override
  Future<Either<AuthFailure, CalendarMonth>> month(String month) {
    if (!_month.hasMatch(month)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    final year = int.parse(month.substring(0, 4));
    final monthNum = int.parse(month.substring(5, 7));
    if (monthNum < 1 || monthNum > 12 || year < 1) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.month(month);
  }
}
