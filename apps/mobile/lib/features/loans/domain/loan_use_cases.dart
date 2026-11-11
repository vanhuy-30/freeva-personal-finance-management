import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'loan.dart';
import 'loan_repository.dart';
import '../../server_config/domain/app_limits.dart';

abstract class LoanUseCases {
  Future<Either<AuthFailure, List<Loan>>> list();
  Future<Either<AuthFailure, List<LoanTotal>>> totals();
  Future<Either<AuthFailure, List<LoanScheduleRow>>> schedule(String id);
  Future<Either<AuthFailure, Loan>> create(LoanDraft draft);
  Future<Either<AuthFailure, Loan>> update(
    Loan loan, {
    required LoanKind kind,
    required String name,
    required int interestRateBps,
    required BigInt? installmentMinor,
    required LoanFrequency frequency,
    required String? endDate,
    required String? nextDueDate,
    required String? accountId,
  });
  Future<Either<AuthFailure, Loan>> adjust(Loan loan, BigInt outstandingMinor);
  Future<Either<AuthFailure, Loan>> pay(Loan loan, LoanPayment payment);
}

@LazySingleton(as: LoanUseCases)
class DefaultLoanUseCases implements LoanUseCases {
  DefaultLoanUseCases(this._repository, this._limits);

  /// Server limits (MOB-P5-001).
  final AppLimitsSource _limits;
  final LoanRepository _repository;

  static final _day = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const _invalid = AuthFailure(AuthError.invalidInput);

  bool _name(String name) =>
      name.trim().isNotEmpty &&
      name.trim().length <= _limits.requireLimits.loanNameMaxLength;
  bool _rate(int bps) => bps >= 0 && bps <= 100000;
  bool _date(String? day) => day == null || _day.hasMatch(day);

  @override
  Future<Either<AuthFailure, List<Loan>>> list() => _repository.list();

  @override
  Future<Either<AuthFailure, List<LoanTotal>>> totals() => _repository.totals();

  @override
  Future<Either<AuthFailure, List<LoanScheduleRow>>> schedule(String id) =>
      _repository.schedule(id);

  @override
  Future<Either<AuthFailure, Loan>> create(LoanDraft draft) {
    final end = draft.endDate;
    final next = draft.nextDueDate;
    if (!_name(draft.name) ||
        draft.principalMinor <= BigInt.zero ||
        draft.outstandingMinor < BigInt.zero ||
        draft.outstandingMinor > draft.principalMinor ||
        !_rate(draft.interestRateBps) ||
        (draft.installmentMinor ?? BigInt.zero) < BigInt.zero ||
        !_day.hasMatch(draft.startDate) ||
        !_date(end) ||
        !_date(next) ||
        (end != null && end.compareTo(draft.startDate) < 0) ||
        (next != null && next.compareTo(draft.startDate) < 0)) {
      return Future.value(left(_invalid));
    }
    return _repository.create(draft);
  }

  @override
  Future<Either<AuthFailure, Loan>> update(
    Loan loan, {
    required LoanKind kind,
    required String name,
    required int interestRateBps,
    required BigInt? installmentMinor,
    required LoanFrequency frequency,
    required String? endDate,
    required String? nextDueDate,
    required String? accountId,
  }) {
    if (!_name(name) ||
        !_rate(interestRateBps) ||
        (installmentMinor ?? BigInt.zero) < BigInt.zero ||
        !_date(endDate) ||
        !_date(nextDueDate)) {
      return Future.value(left(_invalid));
    }
    return _repository.update(
      loan,
      kind: kind,
      name: name.trim(),
      interestRateBps: interestRateBps,
      installmentMinor: installmentMinor,
      frequency: frequency,
      endDate: endDate,
      nextDueDate: nextDueDate,
      accountId: accountId,
    );
  }

  @override
  Future<Either<AuthFailure, Loan>> adjust(Loan loan, BigInt outstandingMinor) {
    if (outstandingMinor < BigInt.zero) return Future.value(left(_invalid));
    return _repository.adjust(loan, outstandingMinor);
  }

  /// Principal never above what is still owed (the API refuses it).
  @override
  Future<Either<AuthFailure, Loan>> pay(Loan loan, LoanPayment payment) {
    if (payment.principalMinor < BigInt.zero ||
        payment.interestMinor < BigInt.zero ||
        payment.amountMinor <= BigInt.zero ||
        payment.principalMinor > loan.outstandingMinor ||
        !_day.hasMatch(payment.paidOn)) {
      return Future.value(left(_invalid));
    }
    return _repository.pay(loan, payment);
  }
}
