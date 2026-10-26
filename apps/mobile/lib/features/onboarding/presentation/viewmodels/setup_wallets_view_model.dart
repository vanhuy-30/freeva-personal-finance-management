import 'package:flutter/foundation.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../sync/domain/sync_queue.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/domain/wallet_use_cases.dart';

/// "Thiết lập tài chính": the wallets added during first-run setup, one per
/// type. Talks to the wallet use cases directly because the main wallet list
/// only works once the app is unlocked; that list loads fresh afterwards.
class SetupWalletsViewModel extends ChangeNotifier {
  SetupWalletsViewModel(this._cases);

  final WalletUseCases _cases;

  /// Account currency for new wallets until the profile can be read here.
  static const mainCurrency = 'VND';

  List<WalletCurrency> currencies = const [];
  final Map<WalletType, Wallet> added = {};
  bool busy = false;
  AuthFailure? failure;

  /// Loads the currency list the form needs; false when that failed.
  Future<bool> ensureCurrencies() async {
    if (currencies.isNotEmpty) return true;
    final result = await _cases.currencies();
    return result.fold(
      (error) {
        failure = error;
        notifyListeners();
        return false;
      },
      (value) {
        currencies = value;
        failure = null;
        return value.isNotEmpty;
      },
    );
  }

  String newClientId() => newSyncOpId();

  /// Creates the wallet; it replaces nothing, a type is added once.
  Future<bool> save(WalletDraft draft, String clientId) async {
    if (busy || added.containsKey(draft.type)) return false;
    busy = true;
    failure = null;
    notifyListeners();
    final result = await _cases.save(draft, currencies, clientId: clientId);
    busy = false;
    result.fold((error) => failure = error, (wallet) {
      added[draft.type] = wallet;
    });
    notifyListeners();
    return failure == null;
  }
}
