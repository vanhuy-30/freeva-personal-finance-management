import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'report.dart';
import 'report_flow.dart';
import 'report_holdings.dart';

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

  /// Income and expense per day, week or month of [query]'s period, never past
  /// today: the points of the cash flow chart.
  Future<Either<AuthFailure, FlowReport>> flow(ReportPeriodQuery query);

  /// How debt and investments moved during [query]'s period.
  Future<Either<AuthFailure, HoldingsReport>> holdings(ReportPeriodQuery query);
  Future<Either<AuthFailure, NetWorthReport>> netWorth({
    String? displayCurrency,
  });
}
