import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/transaction_filter.dart';
import '../../../transactions/domain/transaction_use_cases.dart';
import '../../../transactions/presentation/viewmodels/transaction_results_view_model.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/wallet_flow.dart';

/// One wallet's screen: its transactions by day and this month's in / out.
/// Short-lived; the page disposes it.
abstract class WalletDetailViewModel extends ChangeNotifier {
  String get walletId;
  TransactionResultsViewModel get results;

  /// Null while loading or after a failure.
  WalletFlow? get flow;
  bool get flowFailed;
  Future<void> reload();
}

@Injectable(as: WalletDetailViewModel)
class DefaultWalletDetailViewModel extends WalletDetailViewModel {
  DefaultWalletDetailViewModel(
    this._cases,
    this._main, {
    @factoryParam required String walletId,
  }) : walletId = walletId,
       results = DefaultTransactionResultsViewModel(
         _cases,
         _main,
         accountId: walletId,
       ) {
    results.addListener(notifyListeners);
  }

  final TransactionUseCases _cases;
  final TransactionViewModel _main;
  int _epoch = 0;
  bool _disposed = false;

  @override
  final String walletId;
  @override
  final TransactionResultsViewModel results;
  @override
  WalletFlow? flow;
  @override
  bool flowFailed = false;

  @override
  Future<void> reload() async {
    await Future.wait([results.reload(), _loadFlow()]);
  }

  Future<void> _loadFlow() async {
    final epoch = ++_epoch;
    flowFailed = false;
    _notify();
    final month = TransactionFilter(accountIds: {walletId});
    final result = await _cases.list(_main.queryFor(month, pageSize: 1));
    if (epoch != _epoch || _disposed) return;
    result.fold((_) {
      flow = null;
      flowFailed = true;
    }, (page) => flow = WalletFlow.fromTotals(page.summary.totals));
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    results.removeListener(notifyListeners);
    results.dispose();
    super.dispose();
  }
}
