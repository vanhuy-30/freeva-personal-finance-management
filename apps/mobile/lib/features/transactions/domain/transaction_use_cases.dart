import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../categories/domain/finance_category.dart';
import '../../tags/domain/tag.dart';
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
    List<FinanceCategory> categories,
    List<Tag> tags, {
    TransactionBundle? existing,
  });
  Future<Either<AuthFailure, Unit>> remove(
    TransactionBundle bundle, {
    RefundDisposition? refunds,
  });

  /// `MOB-P3-008`: money back for the expense [original], at most what is
  /// still [TransactionBundle.refundable].
  Future<Either<AuthFailure, TransactionBundle>> refund(
    TransactionBundle original,
    RefundCommand command,
  );

  /// Changes the signed amount of an `adjustment`; nothing else on it moves.
  Future<Either<AuthFailure, TransactionBundle>> adjust(
    TransactionBundle bundle,
    BigInt signedMinor,
  );
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
        pageSize: query.pageSize,
        deleted: query.deleted,
        type: query.type,
        search: search == null || search.isEmpty ? null : search,
        from: query.from,
        to: query.to,
        accountIds: query.accountIds,
        categoryIds: query.categoryIds,
        tagIds: query.tagIds,
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
    List<FinanceCategory> categories,
    List<Tag> tags, {
    TransactionBundle? existing,
  }) {
    final command = prepareTransaction(
      draft,
      wallets,
      currencies,
      categories,
      tags,
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
  Future<Either<AuthFailure, TransactionBundle>> adjust(
    TransactionBundle bundle,
    BigInt signedMinor,
  ) {
    final leg = bundle.legs.first;
    final max = BigInt.parse('9223372036854775807');
    if (bundle.type != TransactionType.adjustment ||
        bundle.deleted ||
        bundle.version < 1 ||
        bundle.version > 2147483646 ||
        signedMinor == BigInt.zero ||
        signedMinor.abs() > max) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.update(
      bundle.id,
      TransactionCommand(
        type: TransactionType.adjustment,
        occurredOn: bundle.occurredOn,
        occurredTime: bundle.occurredTime,
        categoryId: null,
        notes: bundle.notes,
        merchant: null,
        tagIds: const [],
        version: bundle.version,
        legs: [
          TransactionLegCommand(
            clientId: leg.clientId,
            accountId: leg.accountId,
            currencyCode: leg.currencyCode,
            amountMinor: signedMinor,
          ),
        ],
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> remove(
    TransactionBundle bundle, {
    RefundDisposition? refunds,
  }) {
    if (bundle.version < 1 || bundle.version > 2147483646) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.remove(bundle.id, bundle.version, refunds: refunds);
  }

  @override
  Future<Either<AuthFailure, TransactionBundle>> refund(
    TransactionBundle original,
    RefundCommand command,
  ) {
    if (original.type != TransactionType.expense || original.deleted) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    if (command.amountMinor <= BigInt.zero) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (command.amountMinor > original.refundable) {
      return Future.value(left(const AuthFailure(AuthError.refundExceeds)));
    }
    return _repository.refund(original.id, command);
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
