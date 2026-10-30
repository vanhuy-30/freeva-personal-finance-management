import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'report.dart';

abstract class ReportRepository {
  /// [displayCurrency] also asks for `converted` totals in that currency.
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query, {
    String? displayCurrency,
  });

  /// Fiscal-month review: totals and top expense categories for [on]
  /// (today when null). Numbers match cashflow for the same month.
  Future<Either<AuthFailure, MonthReviewReport>> monthReview({String? on});

  /// Expense and income per bucket for [kind] (week, month or year), ending at
  /// the period that holds [on] (today when null).
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  });
  Future<Either<AuthFailure, NetWorthReport>> netWorth({String? displayCurrency});
}
