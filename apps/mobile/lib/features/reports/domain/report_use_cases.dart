import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../categories/domain/category_repository.dart';
import '../../wallets/domain/wallet_repository.dart';
import 'report.dart';
import 'report_names.dart';
import 'report_period.dart';
import 'report_repository.dart';

abstract class ReportUseCases {
  Future<Either<AuthFailure, NamedCashflow>> loadCashflow(
    ReportPeriodQuery query,
  );

  /// Totals of the period before [period]; the screen works without them.
  Future<Either<AuthFailure, CashflowReport>> loadPrevious(ReportPeriod period);

  /// Month review for the fiscal month that holds [on] (today when null).
  Future<Either<AuthFailure, NamedMonthReview>> loadMonthReview({String? on});

  Future<Either<AuthFailure, TrendReport>> loadTrend(
    ReportPeriodKind kind, {
    String? on,
  });
}

@LazySingleton(as: ReportUseCases)
class DefaultReportUseCases implements ReportUseCases {
  DefaultReportUseCases(this._reports, this._wallets, this._categories);

  final ReportRepository _reports;
  final WalletRepository _wallets;
  final CategoryRepository _categories;

  @override
  Future<Either<AuthFailure, NamedCashflow>> loadCashflow(
    ReportPeriodQuery query,
  ) async {
    final invalid = invalidPeriod(query);
    if (invalid != null) return left(invalid);
    final flow = await _reports.cashflow(query);
    return _and(flow, (report) async {
      final wallets = await _wallets.load();
      return _and(wallets, (accounts) async {
        final categories = await _categories.manage();
        return _and(categories, (catalog) async {
          final currencies = await _wallets.currencies();
          return currencies.fold(
            left,
            (codes) => nameCashflow(report, accounts, catalog.items, codes),
          );
        });
      });
    });
  }

  @override
  Future<Either<AuthFailure, CashflowReport>> loadPrevious(
    ReportPeriod period,
  ) async {
    final query = previousPeriod(period);
    if (query == null) return left(const AuthFailure(AuthError.invalidInput));
    return _reports.cashflow(query);
  }

  @override
  Future<Either<AuthFailure, NamedMonthReview>> loadMonthReview({
    String? on,
  }) async {
    if (on != null && invalidPeriod(ReportPeriodQuery.month(on: on)) != null) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    final review = await _reports.monthReview(on: on);
    return _and(review, (report) async {
      final categories = await _categories.manage();
      return _and(categories, (catalog) async {
        final currencies = await _wallets.currencies();
        return currencies.fold(
          left,
          (codes) => nameMonthReview(report, catalog.items, codes),
        );
      });
    });
  }

  @override
  Future<Either<AuthFailure, TrendReport>> loadTrend(
    ReportPeriodKind kind, {
    String? on,
  }) => _reports.trend(kind, on: on);
}

Future<Either<AuthFailure, R>> _and<T, R>(
  Either<AuthFailure, T> current,
  Future<Either<AuthFailure, R>> Function(T value) next,
) => current.fold((error) async => left(error), next);
