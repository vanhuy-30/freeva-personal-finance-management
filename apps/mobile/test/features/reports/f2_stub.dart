import 'package:dartz/dartz.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/reports/domain/category_detail.dart';
import 'package:mobile/features/reports/domain/report_breakdown.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_repository.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';

import '../transactions/c1_stub.dart';
import 'f1_stub.dart';

/// Slice [index] of October's expense breakdown (0 = Ăn uống, 3 = Khác).
CategoryDetailArgs f2Args({int index = 0, BreakdownKind? kind}) {
  final report = october();
  final type = kind ?? BreakdownKind.expense;
  final slices = reportBreakdown(report, 'VND', type).slices;
  return CategoryDetailArgs(
    report: report,
    currency: 'VND',
    digits: 0,
    kind: type,
    slice: slices[index],
  );
}

/// The three largest food transactions of the canvas (RepCategory).
List<TxLeg> largestLegs() => [
  tx(
    'l1',
    account: 'cash',
    amount: -486000,
    day: '2026-10-19',
    category: 'food',
    merchant: 'Co.opmart',
  ),
  tx(
    'l2',
    account: 'vcb',
    amount: -400000,
    day: '2026-10-18',
    category: 'food',
    merchant: 'Nhà hàng Ngon',
  ),
  tx(
    'l3',
    account: 'cash',
    amount: -312000,
    day: '2026-10-12',
    category: 'coffee',
    merchant: 'Bách hoá Xanh',
  ),
];

class FakeTransactionRepository implements TransactionRepository {
  final queries = <TransactionQuery>[];
  AuthFailure? failure;
  int total = 42;

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async {
    queries.add(query);
    final error = failure;
    if (error != null) return left(error);
    return right(
      TransactionListPage(legs: largestLegs(), page: 1, total: total),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Registers what the category screen reads from the container.
Future<void> registerF2(
  FakeTransactionRepository repository,
  StubTransactionViewModel transactions,
) async {
  getIt.registerSingleton<TransactionRepository>(repository);
  getIt.registerSingleton<TransactionViewModel>(transactions);
}
