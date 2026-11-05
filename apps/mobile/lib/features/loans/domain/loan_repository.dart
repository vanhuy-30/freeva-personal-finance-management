import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'loan.dart';

abstract class LoanRepository {
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
