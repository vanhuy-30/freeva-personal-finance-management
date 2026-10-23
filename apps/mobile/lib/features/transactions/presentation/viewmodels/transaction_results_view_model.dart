import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_filter.dart';
import '../../domain/transaction_use_cases.dart';
import 'transaction_view_model.dart';

/// A second, short-lived result list (search screen, deleted screen) so the
/// main list keeps its own filter. Names and dates come from the main model.
abstract class TransactionResultsViewModel extends ChangeNotifier {
  List<TransactionBundle> get rows;
  TransactionSummary get summary;
  TransactionFilter get filter;
  bool get loading;
  bool get hasMore;
  AuthFailure? get failure;

  /// Search text is applied after 300 ms of no typing.
  void setSearch(String text);
  Future<void> setFilter(TransactionFilter value);
  Future<void> reload();
  Future<void> loadMore();
}

@Injectable(as: TransactionResultsViewModel)
class DefaultTransactionResultsViewModel extends TransactionResultsViewModel {
  DefaultTransactionResultsViewModel(
    this._cases,
    this._main, {
    @factoryParam bool? deleted,
  }) : _deleted = deleted ?? false,
       filter = (deleted ?? false)
           ? const TransactionFilter(period: PeriodPreset.allTime)
           : TransactionFilter.searching;

  static const debounce = Duration(milliseconds: 300);

  final TransactionUseCases _cases;
  final TransactionViewModel _main;
  final bool _deleted;
  Timer? _timer;
  int _epoch = 0;
  int _page = 1;
  int _total = 0;
  List<TxLeg> _legs = const [];
  bool _disposed = false;

  @override
  TransactionFilter filter;
  @override
  TransactionSummary summary = TransactionSummary.empty;
  @override
  bool loading = false;
  @override
  AuthFailure? failure;
  @override
  List<TransactionBundle> get rows => groupTransactionLegs(_legs);
  @override
  bool get hasMore => _legs.length < _total;

  /// Search with no text shows nothing yet (deleted list always loads).
  bool get _idle => !_deleted && (filter.search?.trim().isEmpty ?? true);

  @override
  void setSearch(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () => setFilter(filter.copyWith(search: text)));
  }

  @override
  Future<void> setFilter(TransactionFilter value) {
    filter = value;
    return reload();
  }

  @override
  Future<void> reload() => _fetch(replace: true);

  @override
  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    _page++;
    await _fetch(replace: false);
  }

  Future<void> _fetch({required bool replace}) async {
    final epoch = ++_epoch;
    if (_idle) {
      _legs = const [];
      _total = 0;
      summary = TransactionSummary.empty;
      loading = false;
      _notify();
      return;
    }
    loading = true;
    failure = null;
    _notify();
    final result = await _cases.list(
      _main.queryFor(filter, page: replace ? 1 : _page, deleted: _deleted),
    );
    if (epoch != _epoch || _disposed) return;
    result.fold((error) => failure = error, (page) {
      _legs = List.unmodifiable(replace ? page.legs : [..._legs, ...page.legs]);
      _page = page.page;
      _total = page.total;
      summary = page.summary;
    });
    loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
