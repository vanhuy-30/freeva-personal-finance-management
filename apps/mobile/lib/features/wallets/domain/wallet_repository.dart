import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
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
}
