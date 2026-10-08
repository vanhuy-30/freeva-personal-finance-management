import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'wallet.dart';
import 'wallet_repository.dart';

abstract class WalletUseCases {
  Future<Either<AuthFailure, List<Wallet>>> load();
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies();
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  });
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft draft,
    List<WalletCurrency> currencies, {
    Wallet? wallet,
    required String clientId,
  });
}

@LazySingleton(as: WalletUseCases)
class DefaultWalletUseCases implements WalletUseCases {
  DefaultWalletUseCases(this._repository);
  final WalletRepository _repository;
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() => _repository.load();
  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() =>
      _repository.currencies();
  @override
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  }) {
    if (wallet.version >= 2147483647 ||
        (sortOrder != null && (sortOrder < 0 || sortOrder > 2147483647))) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.update(wallet, archived: archived, sortOrder: sortOrder);
  }

  @override
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft draft,
    List<WalletCurrency> currencies, {
    Wallet? wallet,
    required String clientId,
  }) {
    final min = BigInt.parse('-9223372036854775808');
    final max = BigInt.parse('9223372036854775807');
    bool day(int? value) => value == null || (value >= 1 && value <= 28);
    if (draft.name.trim().isEmpty ||
        draft.name.trim().length > 100 ||
        !currencies.any((c) => c.code == draft.currency) ||
        draft.initialBalance < min ||
        draft.initialBalance > max ||
        (draft.creditLimit != null &&
            (draft.creditLimit! < BigInt.zero || draft.creditLimit! > max)) ||
        !day(draft.closeDay) ||
        !day(draft.dueDay) ||
        (draft.type != WalletType.credit &&
            (draft.creditLimit != null ||
                draft.closeDay != null ||
                draft.dueDay != null))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (wallet != null && wallet.version >= 2147483647) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.save(draft, wallet: wallet, clientId: clientId);
  }
}
