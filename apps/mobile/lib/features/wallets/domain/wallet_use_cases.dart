import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'reconcile_result.dart';
import 'wallet.dart';
import 'wallet_repository.dart';
import '../../server_config/domain/app_limits.dart';

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

  /// All active wallets in their new order.
  Future<Either<AuthFailure, List<Wallet>>> reorder(List<Wallet> active);

  Future<Either<AuthFailure, ReconcileResult>> reconcile(
    Wallet wallet,
    BigInt actualMinor, {
    required String clientId,
    bool dryRun = false,
  });
}

@LazySingleton(as: WalletUseCases)
class DefaultWalletUseCases implements WalletUseCases {
  DefaultWalletUseCases(this._repository, this._limits);

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
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
  Future<Either<AuthFailure, ReconcileResult>> reconcile(
    Wallet wallet,
    BigInt actualMinor, {
    required String clientId,
    bool dryRun = false,
  }) {
    final max = BigInt.parse('9223372036854775807');
    // A debt is typed as a positive amount; a wallet may be overdrawn.
    final credit = wallet.draft.type == WalletType.credit;
    if (wallet.archived ||
        actualMinor.abs() > max ||
        (credit && actualMinor < BigInt.zero)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.reconcile(
      wallet,
      actualMinor,
      clientId: clientId,
      dryRun: dryRun,
    );
  }

  @override
  Future<Either<AuthFailure, List<Wallet>>> reorder(List<Wallet> active) {
    final ids = active.map((w) => w.id).toSet();
    if (active.isEmpty ||
        ids.length != active.length ||
        active.any((w) => w.archived || w.version >= 2147483647)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.reorder(active);
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
    bool day(int? value) =>
        value == null ||
        (value >= 1 && value <= _limits.requireLimits.periodStartDayMax);
    if (draft.name.trim().isEmpty ||
        draft.name.trim().length > _limits.requireLimits.walletNameMaxLength ||
        !currencies.any((c) => c.code == draft.currency) ||
        draft.initialBalance < min ||
        draft.initialBalance > max ||
        (draft.creditLimit != null &&
            (draft.creditLimit! < BigInt.zero || draft.creditLimit! > max)) ||
        (draft.minimumPayment != null &&
            (draft.minimumPayment! < BigInt.zero ||
                draft.minimumPayment! > max)) ||
        !day(draft.closeDay) ||
        !day(draft.dueDay) ||
        (draft.type != WalletType.credit &&
            (draft.creditLimit != null ||
                draft.closeDay != null ||
                draft.dueDay != null ||
                draft.minimumPayment != null))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (wallet != null && wallet.version >= 2147483647) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.save(draft, wallet: wallet, clientId: clientId);
  }
}
