import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/recurring/domain/recurring_repository.dart';
import 'package:mobile/features/recurring/domain/recurring_rule.dart';
import 'package:mobile/features/recurring/domain/recurring_use_cases.dart';

class _FakeRepo implements RecurringRepository {
  RecurringDraft? last;
  @override
  Future<Either<AuthFailure, RecurringRule>> create(RecurringDraft draft) async {
    last = draft;
    return right(
      RecurringRule(
        id: 'id',
        clientId: draft.clientId,
        type: draft.type,
        unit: draft.unit,
        interval: draft.interval,
        amountMinor: draft.amountMinor,
        currencyCode: draft.currencyCode,
        accountId: draft.accountId,
        categoryId: draft.categoryId,
        counterAccountId: draft.counterAccountId,
        counterAmountMinor: draft.counterAmountMinor,
        counterCurrencyCode: draft.counterCurrencyCode,
        fxRate: draft.fxRate,
        startDate: draft.startDate,
        endDate: draft.endDate,
        nextExecutionDate: draft.nextExecutionDate,
        active: draft.active,
        version: 1,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(RecurringRule rule) async =>
      right(unit);

  @override
  Future<Either<AuthFailure, List<RecurringRule>>> list({bool? active}) async =>
      right(const []);

  @override
  Future<Either<AuthFailure, RecurringRunResult>> run() async =>
      right(const RecurringRunResult(created: 0, skipped: 0));

  @override
  Future<Either<AuthFailure, RecurringRule>> update(
    RecurringRule rule, {
    String? unit,
    int? interval,
    BigInt? amountMinor,
    String? currencyCode,
    String? accountId,
    String? categoryId,
    bool clearCategory = false,
    String? counterAccountId,
    bool clearCounter = false,
    BigInt? counterAmountMinor,
    String? counterCurrencyCode,
    String? fxRate,
    bool clearFx = false,
    String? startDate,
    String? endDate,
    bool clearEnd = false,
    String? nextExecutionDate,
    bool? active,
  }) async => right(rule);
}

void main() {
  test('rejects expense without category and accepts transfer balance', () async {
    final repo = _FakeRepo();
    final cases = DefaultRecurringUseCases(repo);
    final bad = await cases.create(
      RecurringDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        type: 'expense',
        unit: 'month',
        interval: 1,
        amountMinor: BigInt.from(-1000),
        currencyCode: 'VND',
        accountId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        categoryId: null,
        counterAccountId: null,
        counterAmountMinor: null,
        counterCurrencyCode: null,
        fxRate: null,
        startDate: '2026-01-01',
        endDate: null,
        nextExecutionDate: '2026-01-01',
        active: true,
      ),
    );
    expect(bad.isLeft(), isTrue);

    final ok = await cases.create(
      RecurringDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        type: 'transfer',
        unit: 'week',
        interval: 1,
        amountMinor: BigInt.from(-200000),
        currencyCode: 'VND',
        accountId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
        categoryId: null,
        counterAccountId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
        counterAmountMinor: BigInt.from(200000),
        counterCurrencyCode: 'VND',
        fxRate: null,
        startDate: '2026-01-05',
        endDate: null,
        nextExecutionDate: '2026-01-05',
        active: true,
      ),
    );
    expect(ok.isRight(), isTrue);
    expect(repo.last?.type, 'transfer');
  });
}
