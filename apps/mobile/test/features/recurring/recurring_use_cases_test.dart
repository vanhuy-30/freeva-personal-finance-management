import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/recurring/domain/recurring_repository.dart';
import 'package:mobile/features/recurring/domain/recurring_rule.dart';
import 'package:mobile/features/recurring/domain/recurring_use_cases.dart';

class _FakeRepo implements RecurringRepository {
  RecurringDraft? last;
  @override
  Future<Either<AuthFailure, RecurringRule>> create(
    RecurringDraft draft,
  ) async {
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
        mode: draft.mode,
        name: draft.name,
        amountKind: draft.amountKind,
        remindDaysBefore: draft.remindDaysBefore,
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
    String? name,
    String? amountKind,
    int? remindDaysBefore,
  }) async => right(rule);

  RecurringConfirm? confirmed;

  @override
  Future<Either<AuthFailure, RecurringConfirmResult>> confirm(
    RecurringRule rule,
    RecurringConfirm confirm,
  ) async {
    confirmed = confirm;
    return right(
      RecurringConfirmResult(rule: rule, transactionId: 'tx', replayed: false),
    );
  }
}

void main() {
  test(
    'rejects expense without category and accepts transfer balance',
    () async {
      final repo = _FakeRepo();
      final cases = DefaultRecurringUseCases(repo, testServerConfigModel());
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
          remindDaysBefore: 3,
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
          remindDaysBefore: 3,
        ),
      );
      expect(ok.isRight(), isTrue);
      expect(repo.last?.type, 'transfer');
    },
  );

  RecurringDraft bill({
    String? name = 'Tiền điện',
    String type = 'expense',
    BigInt? amount,
    String? accountId,
  }) => RecurringDraft(
    clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    type: type,
    mode: 'remind',
    name: name,
    amountKind: 'estimated',
    remindDaysBefore: 3,
    unit: 'month',
    interval: 1,
    amountMinor: amount ?? BigInt.from(-850000),
    currencyCode: 'VND',
    accountId: accountId,
    categoryId: null,
    counterAccountId: null,
    counterAmountMinor: null,
    counterCurrencyCode: null,
    fxRate: null,
    startDate: '2026-11-05',
    endDate: null,
    nextExecutionDate: '2026-11-05',
    active: true,
  );

  group('remind rules (bills)', () {
    test('need a name, an expense and a negative amount; wallet and category '
        'are optional', () async {
      final cases = DefaultRecurringUseCases(
        _FakeRepo(),
        testServerConfigModel(),
      );
      expect((await cases.create(bill())).isRight(), isTrue);
      expect((await cases.create(bill(name: ' '))).isLeft(), isTrue);
      expect((await cases.create(bill(type: 'income'))).isLeft(), isTrue);
      expect(
        (await cases.create(bill(amount: BigInt.from(850000)))).isLeft(),
        isTrue,
      );
    });

    test('an auto rule still needs a wallet', () async {
      final cases = DefaultRecurringUseCases(
        _FakeRepo(),
        testServerConfigModel(),
      );
      final auto = RecurringDraft(
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        type: 'income',
        unit: 'month',
        interval: 1,
        amountMinor: BigInt.from(18500000),
        currencyCode: 'VND',
        accountId: null,
        categoryId: null,
        counterAccountId: null,
        counterAmountMinor: null,
        counterCurrencyCode: null,
        fxRate: null,
        startDate: '2026-11-05',
        endDate: null,
        nextExecutionDate: '2026-11-05',
        active: true,
        remindDaysBefore: 3,
      );
      expect((await cases.create(auto)).isLeft(), isTrue);
    });
  });

  group('confirm', () {
    RecurringRule rule({String mode = 'remind'}) => RecurringRule(
      id: 'r1',
      clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      type: 'expense',
      unit: 'month',
      interval: 1,
      amountMinor: BigInt.from(-850000),
      currencyCode: 'VND',
      accountId: null,
      categoryId: null,
      counterAccountId: null,
      counterAmountMinor: null,
      counterCurrencyCode: null,
      fxRate: null,
      startDate: '2026-11-05',
      endDate: null,
      nextExecutionDate: '2026-11-05',
      active: true,
      version: 1,
      mode: mode,
      name: 'Tiền điện',
      remindDaysBefore: 3,
    );

    test('passes the due day, wallet and real amount through', () async {
      final repo = _FakeRepo();
      final cases = DefaultRecurringUseCases(repo, testServerConfigModel());
      final done = await cases.confirm(
        rule(),
        RecurringConfirm(
          occurredOn: '2026-11-05',
          accountId: 'w1',
          amountMinor: BigInt.from(872000),
        ),
      );
      expect(done.isRight(), isTrue);
      expect(repo.confirmed?.amountMinor, BigInt.from(872000));
    });

    test(
      'rejects an auto rule, a zero amount and a link plus amount',
      () async {
        final cases = DefaultRecurringUseCases(
          _FakeRepo(),
          testServerConfigModel(),
        );
        const day = '2026-11-05';
        expect(
          (await cases.confirm(
            rule(mode: 'auto'),
            const RecurringConfirm(occurredOn: day, accountId: 'w1'),
          )).isLeft(),
          isTrue,
        );
        expect(
          (await cases.confirm(
            rule(),
            RecurringConfirm(occurredOn: day, amountMinor: BigInt.zero),
          )).isLeft(),
          isTrue,
        );
        expect(
          (await cases.confirm(
            rule(),
            RecurringConfirm(
              occurredOn: day,
              transactionId: 't1',
              amountMinor: BigInt.one,
            ),
          )).isLeft(),
          isTrue,
        );
        expect(
          (await cases.confirm(
            rule(),
            const RecurringConfirm(occurredOn: day, transactionId: 't1'),
          )).isRight(),
          isTrue,
        );
      },
    );
  });
}
