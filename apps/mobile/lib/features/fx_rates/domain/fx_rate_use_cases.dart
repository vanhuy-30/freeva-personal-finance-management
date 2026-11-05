import 'package:injectable/injectable.dart';

import '../../../core/money/display_converted.dart';
import '../../../core/money/currency_usage.dart';
import '../../wallets/domain/wallet_repository.dart';
import 'fx_rate_repository.dart';

/// Converted amounts for detail screens. Display only and best effort: a
/// failure or a missing rate just means no converted line.
@injectable
class FxRateUseCases {
  FxRateUseCases(this._repository, this._wallets);

  final FxRateRepository _repository;
  final WalletRepository _wallets;

  Future<DisplayConverted?> walletConverted(String walletId) async {
    if (!await _multiCurrency()) return null;
    return (await _repository.walletConverted(walletId))
        .fold((_) => null, (v) => v);
  }

  Future<DisplayConverted?> transactionConverted(String legId) async {
    if (!await _multiCurrency()) return null;
    return (await _repository.transactionConverted(legId))
        .fold((_) => null, (v) => v);
  }

  /// False when the wallets (archived too) use one currency, or cannot be
  /// loaded: no converted line is better than a made-up one.
  Future<bool> _multiCurrency() async => (await _wallets.load()).fold(
    (_) => false,
    (all) => usesMultipleCurrencies([for (final w in all) w.draft.currency]),
  );
}
