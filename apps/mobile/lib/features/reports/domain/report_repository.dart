import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'report.dart';

abstract class ReportRepository {
  Future<Either<AuthFailure, CashflowReport>> cashflow(ReportPeriodQuery query);
  Future<Either<AuthFailure, NetWorthReport>> netWorth();
}
