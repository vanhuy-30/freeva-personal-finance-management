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
  Future<Either<AuthFailure, OverviewSnapshot>> loadOverview();
  Future<Either<AuthFailure, NamedCashflow>> loadCashflow(
    ReportPeriodQuery query,
  );
}

@LazySingleton(as: ReportUseCases)
class DefaultReportUseCases implements ReportUseCases {
  DefaultReportUseCases(this._reports, this._wallets, this._categories);

  final ReportRepository _reports;
  final WalletRepository _wallets;
  final CategoryRepository _categories;

  @override
  Future<Either<AuthFailure, OverviewSnapshot>> loadOverview() async {
    final worth = await _reports.netWorth();
    return _and(worth, (net) async {
      final flow = await _reports.cashflow(const ReportPeriodQuery.month());
      return _and(flow, (month) async {
        final currencies = await _wallets.currencies();
        return currencies.fold(
          left,
          (codes) => overviewSnapshot(net, month, codes),
        );
      });
    });
  }

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
}

Future<Either<AuthFailure, R>> _and<T, R>(
  Either<AuthFailure, T> current,
  Future<Either<AuthFailure, R>> Function(T value) next,
) => current.fold((error) async => left(error), next);
