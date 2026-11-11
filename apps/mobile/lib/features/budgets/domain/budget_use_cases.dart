import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../server_config/domain/app_limits.dart';

import '../../auth/domain/auth_repository.dart';
import 'budget.dart';
import 'budget_repository.dart';

abstract class BudgetUseCases {
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

@LazySingleton(as: BudgetUseCases)
class DefaultBudgetUseCases implements BudgetUseCases {
  DefaultBudgetUseCases(this._repository, this._limits);

  final BudgetRepository _repository;
  final AppLimitsSource _limits;

  AuthFailure? _validate(BudgetDraft draft) {
    if (draft.limitMinor <= BigInt.zero) {
      return const AuthFailure(AuthError.invalidInput);
    }
    if (draft.applyTo == BudgetApplyTo.month &&
        (draft.on == null || draft.on!.isEmpty)) {
      return const AuthFailure(AuthError.invalidInput);
    }
    final rules = _limits.requireLimits;
    final thresholds = draft.alertThresholds;
    if (thresholds.isEmpty || thresholds.length > rules.budgetMaxThresholds) {
      return const AuthFailure(AuthError.invalidInput);
    }
    var previous = 0;
    for (final threshold in thresholds) {
      if (threshold < 1 ||
          threshold > rules.budgetThresholdMax ||
          threshold <= previous) {
        return const AuthFailure(AuthError.invalidInput);
      }
      previous = threshold;
    }
    final seen = <String>{};
    for (final BudgetCategoryDraft line in draft.categories) {
      if (line.limitMinor <= BigInt.zero || !seen.add(line.categoryId)) {
        return const AuthFailure(AuthError.invalidInput);
      }
    }
    return null;
  }

  @override
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  }) => _repository.current(on: on, applyTo: applyTo);

  @override
  Future<Either<AuthFailure, BudgetSummary>> put(BudgetDraft draft) {
    final error = _validate(draft);
    if (error != null) return Future.value(left(error));
    return _repository.put(draft);
  }

  @override
  Future<Either<AuthFailure, Unit>> delete({
    BudgetApplyTo applyTo = BudgetApplyTo.defaultTemplate,
    String? on,
    int? version,
  }) {
    if (applyTo == BudgetApplyTo.month && (on == null || on.isEmpty)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.delete(applyTo: applyTo, on: on, version: version);
  }
}
