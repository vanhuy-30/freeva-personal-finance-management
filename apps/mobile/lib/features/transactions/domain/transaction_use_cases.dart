import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../categories/domain/finance_category.dart';
import '../../wallets/domain/wallet.dart';
import 'transaction.dart';
import 'transaction_repository.dart';
import 'transaction_rules.dart';

abstract class TransactionUseCases {
  Future<Either<AuthFailure, TransactionListPage>> list(TransactionQuery query);
  Future<Either<AuthFailure, TransactionBundle>> read(String id);
  Future<Either<AuthFailure, TransactionBundle>> save(
    TransactionDraft draft,
    List<Wallet> wallets,
    List<WalletCurrency> currencies,
    List<FinanceCategory> categories, {
    TransactionBundle? existing,
  });
  Future<Either<AuthFailure, Unit>> remove(TransactionBundle bundle);
  Future<Either<AuthFailure, TransactionBundle>> restore(
    TransactionBundle bundle,
    List<Wallet> wallets,
  );
}

@LazySingleton(as: TransactionUseCases)
class DefaultTransactionUseCases implements TransactionUseCases {
  DefaultTransactionUseCases(this._repository);
  final TransactionRepository _repository;

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) {
    final search = query.search?.trim();
    if (search != null && search.length > 200) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.list(
      TransactionQuery(
        page: query.page,
        deleted: query.deleted,
        type: query.type,
        search: search == null || search.isEmpty ? null : search,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, TransactionBundle>> read(String id) =>
      _repository.read(id);

  @override
  Future<Either<AuthFailure, TransactionBundle>> save(
    TransactionDraft draft,
    List<Wallet> wallets,
    List<WalletCurrency> currencies,
    List<FinanceCategory> categories, {
    TransactionBundle? existing,
  }) {
    final command = prepareTransaction(
      draft,
      wallets,
      currencies,
      categories,
      existing: existing,
    );
    return command.fold(
      (error) async => left(error),
      (value) => existing == null
          ? _repository.create(value)
          : _repository.update(existing.id, value),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> remove(TransactionBundle bundle) {
    if (bundle.version < 1 || bundle.version > 2147483646) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.remove(bundle.id, bundle.version);
  }

  @override
  Future<Either<AuthFailure, TransactionBundle>> restore(
    TransactionBundle bundle,
    List<Wallet> wallets,
  ) {
    if (!bundle.deleted || bundle.version >= 2147483647) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    final active = wallets.where((wallet) => !wallet.archived).map((w) => w.id);
    if (bundle.legs.any((leg) => !active.contains(leg.accountId))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.restore(bundle.id, bundle.version);
  }
}
