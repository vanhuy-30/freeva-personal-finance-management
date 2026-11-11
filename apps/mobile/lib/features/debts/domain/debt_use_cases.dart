import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'debt_repository.dart';
import 'personal_debt.dart';
import '../../server_config/domain/app_limits.dart';

abstract class DebtUseCases {
  Future<Either<AuthFailure, List<PersonalDebt>>> list();
  Future<Either<AuthFailure, List<DebtTotal>>> totals();
  Future<Either<AuthFailure, PersonalDebt>> create(DebtDraft draft);
  Future<Either<AuthFailure, PersonalDebt>> update(
    PersonalDebt debt, {
    required String counterparty,
    required String? dueDate,
    required String? note,
  });
  Future<Either<AuthFailure, List<DebtPayment>>> payments(String id);
  Future<Either<AuthFailure, PersonalDebt>> repay(
    PersonalDebt debt,
    DebtRepay repay,
  );
}

@LazySingleton(as: DebtUseCases)
class DefaultDebtUseCases implements DebtUseCases {
  DefaultDebtUseCases(this._repository, this._limits);

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
  final DebtRepository _repository;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _invalid = AuthFailure(AuthError.invalidInput);

  bool _name(String name) =>
      name.trim().isNotEmpty &&
      name.trim().length <= _limits.requireLimits.debtNameMaxLength;
  bool _note(String? note) =>
      note == null || note.trim().length <= _limits.requireLimits.noteMaxLength;

  /// The due date may not come before the day the money moved.
  bool _due(String? due, String occurredOn) =>
      due == null || (_day.hasMatch(due) && due.compareTo(occurredOn) >= 0);

  @override
  Future<Either<AuthFailure, List<PersonalDebt>>> list() => _repository.list();

  @override
  Future<Either<AuthFailure, List<DebtTotal>>> totals() => _repository.totals();

  @override
  Future<Either<AuthFailure, PersonalDebt>> create(DebtDraft draft) {
    if (!_name(draft.counterparty) ||
        draft.amountMinor <= BigInt.zero ||
        !_day.hasMatch(draft.occurredOn) ||
        !_due(draft.dueDate, draft.occurredOn) ||
        !_note(draft.note)) {
      return Future.value(left(_invalid));
    }
    return _repository.create(draft);
  }

  @override
  Future<Either<AuthFailure, PersonalDebt>> update(
    PersonalDebt debt, {
    required String counterparty,
    required String? dueDate,
    required String? note,
  }) {
    if (!_name(counterparty) ||
        !_due(dueDate, debt.occurredOn) ||
        !_note(note)) {
      return Future.value(left(_invalid));
    }
    return _repository.update(
      debt,
      counterparty: counterparty.trim(),
      dueDate: dueDate,
      note: note?.trim(),
    );
  }

  @override
  Future<Either<AuthFailure, List<DebtPayment>>> payments(String id) =>
      _repository.payments(id);

  /// Never more than what is still owed: the API refuses an overpayment.
  @override
  Future<Either<AuthFailure, PersonalDebt>> repay(
    PersonalDebt debt,
    DebtRepay repay,
  ) {
    if (repay.amountMinor <= BigInt.zero ||
        repay.amountMinor > debt.outstandingMinor ||
        !_day.hasMatch(repay.paidOn)) {
      return Future.value(left(_invalid));
    }
    return _repository.repay(debt, repay);
  }
}
