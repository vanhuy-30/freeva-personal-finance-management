import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/bills/domain/bill.dart';
import 'package:mobile/features/bills/domain/bill_repository.dart';
import 'package:mobile/features/bills/domain/bill_use_cases.dart';

class _FakeRepo implements BillRepository {
  BillDraft? lastCreate;
  String? lastPayTransactionId;

  @override
  Future<Either<AuthFailure, Bill>> create(BillDraft draft) async {
    lastCreate = draft;
    return right(
      Bill(
        id: 'id',
        clientId: draft.clientId,
        name: draft.name,
        dueOn: draft.dueOn,
        amountMinor: draft.amountMinor,
        amountKind: draft.amountKind,
        currencyCode: draft.currencyCode,
        recurringRuleId: draft.recurringRuleId,
        paidTransactionId: null,
        paid: false,
        overdue: false,
        version: 1,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(Bill bill) async => right(unit);

  @override
  Future<Either<AuthFailure, List<Bill>>> list({String? status}) async =>
      right(const []);

  @override
  Future<Either<AuthFailure, Bill>> pay(Bill bill, String transactionId) async {
    lastPayTransactionId = transactionId;
    return right(
      bill.copyWith(
        paidTransactionId: transactionId,
        paid: true,
        overdue: false,
        version: bill.version + 1,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, Bill>> unpay(Bill bill) async =>
      right(bill.copyWith(clearPaid: true, paid: false));

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
  }) async => right(bill);
}

void main() {
  test('rejects non-positive amounts and empty names', () async {
    final cases = DefaultBillUseCases(_FakeRepo());
    final badAmount = await cases.create(
      BillDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Điện',
        dueOn: '2026-10-15',
        amountMinor: BigInt.zero,
        amountKind: 'fixed',
        currencyCode: 'VND',
        recurringRuleId: null,
      ),
    );
    expect(badAmount.isLeft(), isTrue);

    final badName = await cases.create(
      BillDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: '   ',
        dueOn: '2026-10-15',
        amountMinor: BigInt.from(1000),
        amountKind: 'fixed',
        currencyCode: 'VND',
        recurringRuleId: null,
      ),
    );
    expect(badName.isLeft(), isTrue);
  });

  test('accepts a one-off bill and pay only sends transaction id', () async {
    final repo = _FakeRepo();
    final cases = DefaultBillUseCases(repo);
    final created = await cases.create(
      BillDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: '  Nước  ',
        dueOn: '2026-10-20',
        amountMinor: BigInt.from(120000),
        amountKind: 'estimated',
        currencyCode: 'vnd',
        recurringRuleId: null,
      ),
    );
    expect(created.isRight(), isTrue);
    expect(repo.lastCreate?.name, 'Nước');
    expect(repo.lastCreate?.currencyCode, 'VND');

    final bill = created.getOrElse(() => throw StateError('missing'));
    final paid = await cases.pay(bill, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    expect(paid.isRight(), isTrue);
    expect(repo.lastPayTransactionId, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
  });

  test('rejects unknown status filter', () async {
    final cases = DefaultBillUseCases(_FakeRepo());
    final result = await cases.list(status: 'queued');
    expect(result.isLeft(), isTrue);
  });
}
