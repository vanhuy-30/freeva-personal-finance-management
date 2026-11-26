import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/domain/transaction_repository.dart';
import '../../domain/category_detail.dart';
import '../../domain/report_breakdown.dart';

/// The transactions behind one category slice, ten at a time, in the order
/// the person picked. Built per screen from the report already on display.
class CategoryReportViewModel extends ChangeNotifier {
  CategoryReportViewModel(this._transactions, this._auth, this.args);

  /// Rows per request; "Xem thêm" asks for the next ten.
  static const pageSize = 10;

  final TransactionRepository _transactions;
  final AuthViewModel _auth;
  final CategoryDetailArgs args;
  int _epoch = 0;
  int _page = 0;
  int _legs = 0;

  /// In the chosen order. Empty until loaded or when the slice cannot be
  /// filtered.
  List<TransactionBundle> items = const [];

  /// Transactions in the slice; null until known.
  int? count;
  TransactionSort sort = TransactionSort.date;

  /// First page (or a re-sort) in flight.
  bool loading = false;

  /// A following page in flight.
  bool loadingMore = false;
  AuthFailure? failure;

  /// A failed "Xem thêm" keeps the rows already on screen.
  bool moreFailed = false;

  /// Uncategorised income has no category id to filter by, so the list is
  /// not offered for it.
  bool get available => args.categoryIds != null;

  bool get hasMore => count != null && _legs < count!;

  TransactionType get type => args.kind == BreakdownKind.expense
      ? TransactionType.expense
      : TransactionType.income;

  /// First page again, from the top, in the current order.
  Future<void> load() => _fetch(1);

  Future<void> loadMore() {
    if (loading || loadingMore || !hasMore) return Future.value();
    return _fetch(_page + 1);
  }

  Future<void> setSort(TransactionSort next) {
    if (next == sort) return Future.value();
    sort = next;
    return _fetch(1);
  }

  Future<void> _fetch(int page) async {
    final ids = args.categoryIds;
    if (ids == null) return;
    final more = page > 1;
    final epoch = ++_epoch;
    if (more) {
      loadingMore = true;
      moreFailed = false;
    } else {
      loading = true;
      loadingMore = false;
      failure = null;
    }
    notifyListeners();
    final period = args.report.period;
    final result = await _transactions.list(
      TransactionQuery(
        page: page,
        pageSize: pageSize,
        type: type,
        from: period.from,
        to: period.to,
        categoryIds: ids,
        currency: args.currency,
        sort: sort,
      ),
    );
    if (epoch != _epoch) return;
    result.fold(
      (error) {
        if (more) {
          moreFailed = true;
        } else {
          // Rows in another order than the chip would mislead: show the retry.
          failure = error;
          items = const [];
        }
        if (error.code == AuthError.expired) _auth.sessionExpired();
      },
      (list) {
        _page = page;
        _legs = (more ? _legs : 0) + list.legs.length;
        items = [
          ...(more ? items : const []),
          ...groupTransactionLegs(list.legs),
        ];
        count = list.total;
      },
    );
    loading = false;
    loadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _epoch++;
    super.dispose();
  }
}
