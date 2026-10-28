import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'budget.dart';

abstract class BudgetRepository {
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  });
  Future<Either<AuthFailure, BudgetSummary>> put(BudgetDraft draft);
  Future<Either<AuthFailure, Unit>> delete({
    BudgetApplyTo applyTo = BudgetApplyTo.defaultTemplate,
    String? on,
    int? version,
  });
}
