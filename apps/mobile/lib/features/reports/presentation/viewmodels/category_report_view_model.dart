import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_repository.dart';
import '../../domain/category_detail.dart';
import '../../domain/report_breakdown.dart';

/// The three largest transactions behind one category slice, and how many
/// there are in all. Built per screen from the report already on display.
class CategoryReportViewModel extends ChangeNotifier {
  CategoryReportViewModel(this._transactions, this._auth, this.args);

  static const shown = 3;

  final TransactionRepository _transactions;
  final AuthViewModel _auth;
  final CategoryDetailArgs args;
  int _epoch = 0;

  /// Largest first. Empty until loaded or when the slice cannot be filtered.
  List<TransactionBundle> largest = const [];

  /// Transactions in the slice; null until known.
  int? count;
  bool loading = false;
  AuthFailure? failure;

  /// Uncategorised income has no category id to filter by, so the largest
  /// list is not offered for it.
  bool get available => args.categoryIds != null;

  TransactionType get type => args.kind == BreakdownKind.expense
      ? TransactionType.expense
      : TransactionType.income;

  Future<void> load() async {
    final ids = args.categoryIds;
    if (ids == null || loading) return;
    final epoch = ++_epoch;
    loading = true;
    failure = null;
    notifyListeners();
    final period = args.report.period;
    final result = await _transactions.list(
      TransactionQuery(
        pageSize: shown,
        type: type,
        from: period.from,
        to: period.to,
        categoryIds: ids,
        sort: TransactionSort.amountDesc,
      ),
    );
    if (epoch != _epoch) return;
    result.fold(
      (error) {
        failure = error;
        if (error.code == AuthError.expired) _auth.sessionExpired();
      },
      (page) {
        largest = groupTransactionLegs(page.legs);
        count = page.total;
      },
    );
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _epoch++;
    super.dispose();
  }
}
