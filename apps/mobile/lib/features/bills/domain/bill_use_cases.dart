import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'bill.dart';
import 'bill_repository.dart';

abstract class BillUseCases {
  Future<Either<AuthFailure, List<Bill>>> list({String? status});
  Future<Either<AuthFailure, Bill>> create(BillDraft draft);
  Future<Either<AuthFailure, Bill>> update(
    Bill bill, {
    String? name,
    String? dueOn,
    BigInt? amountMinor,
    String? amountKind,
    String? currencyCode,
    String? recurringRuleId,
    bool clearRule = false,
  });
  Future<Either<AuthFailure, Unit>> delete(Bill bill);
  Future<Either<AuthFailure, Bill>> pay(Bill bill, String transactionId);
  Future<Either<AuthFailure, Bill>> unpay(Bill bill);
}

@LazySingleton(as: BillUseCases)
class DefaultBillUseCases implements BillUseCases {
  DefaultBillUseCases(this._repository);
  final BillRepository _repository;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  AuthFailure? _validate(BillDraft draft) {
    final name = draft.name.trim();
    if (name.isEmpty || name.length > 80) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (!_day.hasMatch(draft.dueOn)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.amountMinor <= BigInt.zero) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (!billAmountKinds.contains(draft.amountKind)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.currencyCode.length != 3) {
      return const AuthFailure(AuthError.invalidInput);
    }
    return null;
  }

  @override
  Future<Either<AuthFailure, List<Bill>>> list({String? status}) {
    if (status != null && !billStatuses.contains(status)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.list(status: status);
  }

  @override
  Future<Either<AuthFailure, Bill>> create(BillDraft draft) {
    final error = _validate(
      BillDraft(
        clientId: draft.clientId,
        name: draft.name.trim(),
        dueOn: draft.dueOn,
        amountMinor: draft.amountMinor,
        amountKind: draft.amountKind,
        currencyCode: draft.currencyCode.toUpperCase(),
        recurringRuleId: draft.recurringRuleId,
      ),
    );
    if (error != null) return Future.value(left(error));
    return _repository.create(
      BillDraft(
        clientId: draft.clientId,
        name: draft.name.trim(),
        dueOn: draft.dueOn,
        amountMinor: draft.amountMinor,
        amountKind: draft.amountKind,
        currencyCode: draft.currencyCode.toUpperCase(),
        recurringRuleId: draft.recurringRuleId,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Bill>> update(
    Bill bill, {
    String? name,
    String? dueOn,
    BigInt? amountMinor,
    String? amountKind,
    String? currencyCode,
    String? recurringRuleId,
    bool clearRule = false,
  }) {
    final next = BillDraft(
      clientId: bill.clientId,
      name: name ?? bill.name,
      dueOn: dueOn ?? bill.dueOn,
      amountMinor: amountMinor ?? bill.amountMinor,
      amountKind: amountKind ?? bill.amountKind,
      currencyCode: currencyCode ?? bill.currencyCode,
      recurringRuleId: clearRule
          ? null
          : (recurringRuleId ?? bill.recurringRuleId),
    );
    final error = _validate(next);
    if (error != null) return Future.value(left(error));
    return _repository.update(
      bill,
      name: name?.trim(),
      dueOn: dueOn,
      amountMinor: amountMinor,
      amountKind: amountKind,
      currencyCode: currencyCode?.toUpperCase(),
      recurringRuleId: recurringRuleId,
      clearRule: clearRule,
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(Bill bill) =>
      _repository.delete(bill);

  @override
  Future<Either<AuthFailure, Bill>> pay(Bill bill, String transactionId) {
    if (transactionId.isEmpty) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.pay(bill, transactionId);
  }

  @override
  Future<Either<AuthFailure, Bill>> unpay(Bill bill) => _repository.unpay(bill);
}
