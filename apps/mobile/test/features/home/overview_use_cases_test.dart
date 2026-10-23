import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/categories/domain/category_repository.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/home/domain/overview_use_cases.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_repository.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_repository.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

import 'fixtures.dart';

void main() {
  late _Reports reports;
  late _Transactions transactions;
  late DefaultOverviewUseCases cases;

  setUp(() {
    reports = _Reports();
    transactions = _Transactions();
    cases = DefaultOverviewUseCases(
      reports,
      _Wallets(),
      transactions,
      _Categories(),
    );
  });

  test('loads the current month only, hides archived wallets', () async {
    reports.months = [month()];
    final data = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(reports.queries.single.on, isNull);
    expect(data.previousMonth, isNull);
    expect(data.wallets.map((w) => w.id), ['vcb']);
    expect(transactions.query?.pageSize, 6);
  });

  test('a transfer counts as one recent row', () async {
    reports.months = [month()];
    transactions.legs = [
      leg(
        'a',
        account: 'vcb',
        amount: -500,
        type: TransactionType.transfer,
        group: 'g',
      ),
      leg(
        'b',
        account: 'momo',
        amount: 500,
        type: TransactionType.transfer,
        group: 'g',
      ),
      leg('c', account: 'vcb', amount: -1),
      leg('d', account: 'vcb', amount: -2),
      leg('e', account: 'vcb', amount: -3),
    ];
    final data = (await cases.load(DateTime(2026, 10, 21)))
        .getOrElse(() => throw StateError('load'));
    expect(data.recent, hasLength(3));
    expect(data.recent.first.legs, hasLength(2));
  });

  test('an empty month also loads the previous month', () async {
    reports.months = [
      month(
        income: 0,
        expense: 0,
        rows: const [],
        from: '2026-11-01',
        to: '2026-11-30',
      ),
      month(),
    ];
    final data = (await cases.load(DateTime(2026, 11, 2)))
        .getOrElse(() => throw StateError('load'));
    expect(reports.queries.last.on, '2026-10-31');
    expect(data.previousMonth, isNotNull);
  });

  test('any required request failing fails the load', () async {
    reports.months = [month()];
    reports.worthFailure = const AuthFailure(AuthError.network);
    final result = await cases.load(DateTime(2026, 10, 21));
    expect(result.isLeft(), isTrue);
  });
}

class _Reports implements ReportRepository {
  List<CashflowReport> months = [];
  final queries = <ReportPeriodQuery>[];
  AuthFailure? worthFailure;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query,
  ) async {
    queries.add(query);
    return right(months.length > 1 ? months.removeAt(0) : months.single);
  }

  @override
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth() async =>
      worthFailure != null
      ? left(worthFailure!)
      : right(NetWorthReport(items: [worth('VND', 100)]));
}

class _Wallets implements WalletRepository {
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right([
    wallet('vcb', 'Vietcombank'),
    wallet('old', 'Cũ', archived: true),
  ]);

  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      right(const [WalletCurrency('VND', 0)]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionRepository {
  TransactionQuery? query;
  List<TxLeg> legs = [];

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async {
    this.query = query;
    return right(TransactionListPage(legs: legs, page: 1, total: legs.length));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() async =>
      right(const CategoryCatalog(all: categories, recent: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
