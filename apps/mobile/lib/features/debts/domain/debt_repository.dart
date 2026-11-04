import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'personal_debt.dart';

abstract class DebtRepository {
  /// Debts not archived, settled ones included.
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
