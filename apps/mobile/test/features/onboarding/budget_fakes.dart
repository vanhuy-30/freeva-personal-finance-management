import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/domain/budget_use_cases.dart';

import '../home/fixtures.dart';

/// Monthly budget for the first-run nudges: none until [put], or one from
/// the start with [hasBudget].
class FakeBudgets implements BudgetUseCases {
  FakeBudgets({this.hasBudget = false});

  bool hasBudget;
  bool failPut = false;
  final puts = <BudgetDraft>[];

  @override
  Future<Either<AuthFailure, BudgetCurrent>> current({
    String? on,
    BudgetApplyTo? applyTo,
  }) async => right(
    BudgetCurrent(
      budget: hasBudget ? budgetOf(12000000, 0) : null,
      period: const BudgetPeriod(
        from: '2026-11-01',
        to: '2026-11-30',
        timezone: 'Asia/Ho_Chi_Minh',
        fiscalMonthStartDay: 1,
      ),
    ),
  );

  @override
  Future<Either<AuthFailure, BudgetSummary>> put(BudgetDraft draft) async {
    if (failPut) return left(const AuthFailure(AuthError.network));
    puts.add(draft);
    hasBudget = true;
    return right(budgetOf(draft.limitMinor.toInt(), 0));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
