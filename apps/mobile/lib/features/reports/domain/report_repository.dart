import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'report.dart';

abstract class ReportRepository {
  Future<Either<AuthFailure, CashflowReport>> cashflow(ReportPeriodQuery query);

  /// Expense and income per bucket for [kind] (week, month or year), ending at
  /// the period that holds [on] (today when null).
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  });
  Future<Either<AuthFailure, NetWorthReport>> netWorth();
}
