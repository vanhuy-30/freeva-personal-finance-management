import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/installments/data/card_installment_repository_impl.dart';
import 'package:mobile/features/installments/domain/card_installment.dart';
import 'package:mobile/features/installments/domain/card_installment_use_cases.dart';
import 'package:mobile/features/installments/presentation/viewmodels/installment_view_model.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_detail_body.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../auth/fakes.dart';
import '../home/fixtures.dart' show b, wallet;
import '../transactions/c1_stub.dart' show tx;
import '../wallets/d1_stub.dart' show StubWalletViewModel, creditCard;
import 'installment_stub.dart';

/// MOB-P3-009: plan parsing, request shapes, the "Chuyển thành trả góp"
/// rule and "Phải trả kỳ này".
void main() {
  late _Api api;
  late CardInstallmentRepositoryImpl repository;
  setUp(() {
    api = _Api();
    repository = CardInstallmentRepositoryImpl(api);
  });

  test('reads a plan with its periods and purchase', () async {
    api.answer = _plan();
    final plan = (await repository.find('p1'))
        .getOrElse(() => throw StateError('failed'));
    expect(api.calls.single.path, 'card-installments/p1');
    expect(plan.totalMinor, b(24000000));
    expect(plan.active, isTrue);
    expect(plan.nextIndex, 2);
    expect(plan.pastCount, 1);
    expect(plan.remainingMinor, b(20000000));
    expect(plan.purchaseMerchant, 'Điện thoại');
    expect(plan.periods!.first.state, InstallmentPeriodState.past);
  });

  test('preview, create, close and due send what the API expects', () async {
    const draft = InstallmentDraft(
      transactionId: 'tx',
      installmentCount: 6,
      firstDueOn: '2026-11-25',
    );
    api.answer = {
      'totalMinor': '24000000',
      'installmentMinor': '4000000',
      'installmentCount': 6,
      'firstDueOn': '2026-11-25',
      'lastDueOn': '2027-04-25',
      'periods': [
        {'index': 1, 'dueOn': '2026-11-25', 'amountMinor': '4000000'},
      ],
    };
    final preview = (await repository.preview(draft))
        .getOrElse(() => throw StateError('failed'));
    expect(preview.installmentMinor, b(4000000));
    expect(preview.lastDueOn, '2027-04-25');
    api.answer = _plan();
    await repository.create(
      InstallmentDraft(
        transactionId: 'tx',
        installmentCount: 3,
        installmentMinor: b(8000000),
        firstDueOn: '2026-11-25',
      ),
      clientId: 'k-1',
    );
    final plan = (await repository.find('p1'))
        .getOrElse(() => throw StateError('failed'));
    await repository.close(plan);
    api.answer = {'from': 'x', 'to': 'y', 'items': <Object>[]};
    await repository.due(from: '2026-10-26', to: '2026-11-25', accountId: 'a');
    await repository.list(accountId: 'a', active: true);
    expect(api.calls.map((c) => '${c.method} ${c.path}'), [
      'POST card-installments/preview',
      'POST card-installments',
      'GET card-installments/p1',
      'POST card-installments/p1/close',
      'GET card-installments/due?from=2026-10-26&to=2026-11-25&accountId=a',
      'GET card-installments?accountId=a&status=active',
    ]);
    expect(api.calls[0].body, {
      'transactionId': 'tx',
      'installmentCount': 6,
      'firstDueOn': '2026-11-25',
    });
    expect(api.calls[1].body, {
      'clientId': 'k-1',
      'transactionId': 'tx',
      'installmentCount': 3,
      'installmentMinor': '8000000',
      'firstDueOn': '2026-11-25',
    });
    expect(api.calls[3].body, {'version': 1});
  });

  test(
    'use cases refuse counts outside 2–60 without calling the API',
    () async {
      final cases = DefaultCardInstallmentUseCases(
        repository,
        testServerConfigModel(),
      );
      for (final n in [1, 61]) {
        final result = await cases.preview(
          InstallmentDraft(
            transactionId: 'tx',
            installmentCount: n,
            firstDueOn: '2026-11-25',
          ),
        );
        expect(result.isLeft(), isTrue);
      }
      expect(api.calls, isEmpty);
    },
  );

  test('expense rows carry installmentPlanId', () async {
    final legs = TransactionRepositoryImpl(api);
    api.answer = {
      'items': [
        {..._leg('e', 'expense'), 'installmentPlanId': 'p1'},
        _leg('f', 'expense'),
      ],
      'page': 1,
      'total': 2,
    };
    final page = (await legs.list(const TransactionQuery()))
        .getOrElse(() => throw StateError('failed'));
    expect(page.legs.map((l) => l.installmentPlanId), ['p1', null]);
  });

  test('"Chuyển thành trả góp" only on a live card expense without a plan', () {
    final card = creditCard();
    final cash = wallet('cash', 'Tiền mặt', type: WalletType.cash);
    TransactionBundle on(
      String account, {
      TransactionType type = TransactionType.expense,
      bool deleted = false,
    }) => TransactionBundle(
      legs: [
        tx(
          'e',
          account: account,
          amount: type == TransactionType.expense ? -1000 : 1000,
          type: type,
          deleted: deleted,
        ),
      ],
    );
    expect(canSplitIntoInstallments(on('card'), [card, cash]), isTrue);
    expect(canSplitIntoInstallments(on('cash'), [card, cash]), isFalse);
    expect(
      canSplitIntoInstallments(on('card', deleted: true), [card, cash]),
      isFalse,
    );
    expect(
      canSplitIntoInstallments(on('card', type: TransactionType.income), [
        card,
        cash,
      ]),
      isFalse,
    );
    final planned = TransactionBundle(
      legs: [
        TxLeg(
          id: 'e',
          clientId: 'c',
          accountId: 'card',
          currencyCode: 'VND',
          amountMinor: b(-1000),
          type: TransactionType.expense,
          occurredOn: '2026-10-12',
          categoryId: null,
          notes: null,
          merchant: null,
          tagIds: const [],
          transferGroupId: null,
          deletedAt: null,
          version: 1,
          createdAt: DateTime.utc(2026),
          installmentPlanId: 'p1',
        ),
      ],
    );
    expect(canSplitIntoInstallments(planned, [card, cash]), isFalse);
  });

  group('dates', () {
    test('first period: due day after the statement holding the purchase', () {
      expect(
        suggestedFirstDue('2026-10-12', closeDay: 20, dueDay: 25),
        '2026-10-25',
      );
      expect(
        suggestedFirstDue('2026-10-22', closeDay: 20, dueDay: 5),
        '2026-12-05',
      );
      expect(
        suggestedFirstDue('2026-10-12', closeDay: 5, dueDay: 25),
        '2026-11-25',
      );
      expect(suggestedFirstDue('2026-10-25', dueDay: 25), '2026-11-25');
      expect(suggestedFirstDue('2026-01-31'), '2026-02-28');
    });

    test('previous due day clamps to the month end', () {
      expect(previousDueDate(DateTime(2026, 3, 28), 31), DateTime(2026, 2, 28));
      expect(
        previousDueDate(DateTime(2026, 1, 25), 25),
        DateTime(2025, 12, 25),
      );
    });

    test('amount due is the debt minus later periods, never below zero', () {
      CardPeriodDue due(int debt, int later) => CardPeriodDue.of(
        dueOn: DateTime(2026, 11, 25),
        debtMinor: b(debt),
        laterMinor: b(later),
        installmentMinor: b(4000000),
      );
      expect(due(35450000, 16000000).amountMinor, b(19450000));
      expect(due(10000000, 16000000).amountMinor, BigInt.zero);
    });
  });

  test(
    'loadCard asks this period and what comes after, from the card dates',
    () async {
      final fake = FakeInstallmentUseCases(
        plans: [phonePlan(withPeriods: false)],
        thisPeriod: b(4000000),
        later: b(16000000),
      );
      final card = creditCard(balance: -35450000, limit: 50000000);
      final model = InstallmentViewModel(
        fake,
        StubWalletViewModel(wallets: [card]),
        DefaultAuthViewModel(
          DefaultAuthUseCases(
            AuthRepositoryImpl(
              FakeApi(),
              MemoryVault(),
              FakeBiometrics(),
              testServerConfigModel(),
            ),
            testServerConfigModel(),
          ),
        )..stage = AuthStage.unlocked,
      );
      await model.loadCard(card);
      // Today 21/10, due on the 25th: this period is 26/09–25/10.
      expect(fake.dueCalls, [
        (from: '2026-09-26', to: '2026-10-25'),
        (from: '2026-10-26', to: '2099-12-31'),
      ]);
      final due = model.periodDueOf(card)!;
      expect(due.dueOn, DateTime(2026, 10, 25));
      expect(due.amountMinor, b(19450000));
      expect(due.installmentMinor, b(4000000));
      expect(model.plansOf('card'), hasLength(1));
    },
  );
}

Map<String, dynamic> _plan() => {
  'id': 'p1',
  'clientId': 'c1',
  'transactionId': 'tx',
  'accountId': 'card',
  'currencyCode': 'VND',
  'totalMinor': '24000000',
  'installmentMinor': '4000000',
  'installmentCount': 6,
  'firstDueOn': '2026-09-25',
  'status': 'active',
  'remainingCount': 5,
  'nextDueOn': '2026-10-25',
  'nextAmountMinor': '4000000',
  'closedAt': null,
  'version': 1,
  'createdAt': '2026-09-01T00:00:00.000Z',
  'updatedAt': '2026-09-01T00:00:00.000Z',
  'purchaseOn': '2026-09-12',
  'purchaseMerchant': 'Điện thoại',
  'purchaseNote': null,
  'purchaseCategoryId': 'shopping',
  'periods': [
    for (var i = 0; i < 6; i++)
      {
        'index': i + 1,
        'dueOn': '2026-${(9 + i).clamp(1, 12).toString().padLeft(2, '0')}-25',
        'amountMinor': '4000000',
        'state': i == 0 ? 'past' : 'upcoming',
      },
  ],
};

Map<String, dynamic> _leg(String id, String type) => {
  'id': id,
  'clientId': 'c-$id',
  'accountId': 'card',
  'currencyCode': 'VND',
  'amountMinor': '-1000',
  'type': type,
  'occurredOn': '2026-10-12',
  'occurredTime': null,
  'categoryId': 'shopping',
  'notes': null,
  'merchant': null,
  'tagIds': <String>[],
  'transferGroupId': null,
  'deletedAt': null,
  'version': 1,
  'createdAt': '2026-10-12T00:00:00.000Z',
  'updatedAt': '2026-10-12T00:00:00.000Z',
};

class _Api implements AuthorizedApi {
  final calls = <({String method, String path, Map<String, dynamic>? body})>[];
  Map<String, dynamic> answer = {};

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body));
    return right(answer);
  }
}
