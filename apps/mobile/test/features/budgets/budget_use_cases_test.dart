import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/domain/budget_repository.dart';
import 'package:mobile/features/budgets/domain/budget_use_cases.dart';

void main() {
  late _Repo repo;
  late DefaultBudgetUseCases cases;

  setUp(() {
    repo = _Repo();
    cases = DefaultBudgetUseCases(repo);
  });

  test('rejects a zero overall limit before calling the API', () async {
    final result = await cases.put(
      BudgetDraft(
        limitMinor: BigInt.zero,
        alertThresholds: defaultAlertThresholds,
        categories: const [],
      ),
    );
    expect(result.fold((e) => e.code, (_) => null), AuthError.invalidInput);
    expect(repo.putCalls, 0);
  });

  test('rejects unsorted alert thresholds', () async {
    final result = await cases.put(
      BudgetDraft(
        limitMinor: BigInt.from(1000),
        alertThresholds: const [90, 70],
        categories: const [],
      ),
    );
    expect(result.fold((e) => e.code, (_) => null), AuthError.invalidInput);
  });

  test('forwards a valid draft', () async {
    repo.summary = _summary();
    final result = await cases.put(
      BudgetDraft(
        limitMinor: BigInt.from(10000000),
        alertThresholds: const [70, 100],
        categories: [
          BudgetCategoryDraft(
            categoryId: 'food',
            limitMinor: BigInt.from(1000000),
          ),
        ],
      ),
    );
    expect(result.isRight(), isTrue);
    expect(repo.putCalls, 1);
  });

  test('month applyTo requires on', () async {
    final result = await cases.put(
      BudgetDraft(
        limitMinor: BigInt.from(10000000),
        alertThresholds: defaultAlertThresholds,
        categories: const [],
        applyTo: BudgetApplyTo.month,
      ),
    );
    expect(result.fold((e) => e.code, (_) => null), AuthError.invalidInput);
    expect(repo.putCalls, 0);
  });
}

BudgetSummary _summary() => BudgetSummary(
      id: 'b1',
      currencyCode: 'VND',
      limitMinor: BigInt.from(10000000),
      spentMinor: BigInt.zero,
      remainingMinor: BigInt.from(10000000),
      percentBps: 0,
      status: BudgetStatus.healthy,
      alertThresholds: const [70, 100],
      crossedThresholds: const [],
      categories: const [],
      period: const BudgetPeriod(
        from: '2026-10-01',
        to: '2026-10-31',
        timezone: 'Asia/Ho_Chi_Minh',
        fiscalMonthStartDay: 1,
      ),
      applyTo: BudgetApplyTo.defaultTemplate,
      isOverride: false,
      version: 1,
    );

class _Repo implements BudgetRepository {
  int putCalls = 0;
  BudgetSummary? summary;

  @override
  Future<Either<AuthFailure, BudgetSummary>> put(BudgetDraft draft) async {
    putCalls++;
    return right(summary!);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
