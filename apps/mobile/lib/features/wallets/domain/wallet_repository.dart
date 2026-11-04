import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'reconcile_result.dart';
import 'wallet.dart';

abstract class WalletRepository {
  Future<Either<AuthFailure, List<Wallet>>> load();
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies();
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft draft, {
    Wallet? wallet,
    required String clientId,
  });
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  });

  /// Asks the server for the difference to [actualMinor] (the real balance,
  /// or the real debt on a credit card) and, unless [dryRun], writes the
  /// adjustment. Retrying with the same [clientId] returns the first result.
  Future<Either<AuthFailure, ReconcileResult>> reconcile(
    Wallet wallet,
    BigInt actualMinor, {
    required String clientId,
    bool dryRun = false,
  });

  /// Saves the order of all [active] wallets at once; returns them reordered.
  Future<Either<AuthFailure, List<Wallet>>> reorder(List<Wallet> active);
}
