import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'calendar_month.dart';

abstract class CalendarRepository {
  Future<Either<AuthFailure, CalendarMonth>> month(String month);
}
