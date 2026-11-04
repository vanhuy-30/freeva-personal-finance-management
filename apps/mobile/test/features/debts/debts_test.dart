import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/debts/data/debt_repository_impl.dart';
import 'package:mobile/features/debts/domain/debt_use_cases.dart';
import 'package:mobile/features/debts/domain/personal_debt.dart';
import 'package:mobile/features/loans/data/loan_repository_impl.dart';
import 'package:mobile/features/loans/domain/loan.dart';
import 'package:mobile/features/loans/domain/loan_use_cases.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import '../home/fixtures.dart' show b;
import 'debt_stub.dart';

/// Records requests and answers with canned JSON per path.
class _Api implements AuthorizedApi {
  _Api(this.responses);
  final Map<String, Map<String, dynamic>> responses;
  final calls = <(String, String, Map<String, dynamic>?)>[];

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method, path, body));
    final r = responses[path];
    return r == null
        ? left(const AuthFailure(AuthError.unavailable))
        : right(r);
  }
}

Map<String, dynamic> _debtJson() => {
  'id': 'd1',
  'clientId': 'c1',
  'direction': 'lent',
  'counterparty': 'Tuấn',
  'currencyCode': 'VND',
  'principalMinor': '3000000',
  'outstandingMinor': '2000000',
  'paidMinor': '1000000',
  'accountId': 'cash',
  'occurredOn': '2026-10-12',
  'dueDate': '2026-10-30',
  'note': null,
  'status': 'open',
  'archivedAt': null,
  'version': 2,
  'createdAt': '2026-10-12T00:00:00.000Z',
  'updatedAt': '2026-10-20T00:00:00.000Z',
};

void main() {
  group('MOB-P3-007 money helpers', () {
    test('"Một nửa" rounds down to a whole unit and never hits zero', () {
      expect(halfOf(b(2000000), 0), b(1000000));
      expect(halfOf(b(2000001), 0), b(1000000));
      expect(halfOf(b(5), 0), b(2));
      expect(halfOf(b(1), 0), b(1));
      // 12.55 USD in cents → 6.00, not 6.27
      expect(halfOf(b(1255), 2), b(600));
      expect(halfOf(b(150), 2), b(75));
    });

    test('progress comes from paid / principal', () {
      expect(debt().progress, closeTo(1 / 3, 0.0001));
      expect(debt(outstanding: 0).progress, 1);
    });
  });

  group('MOB-P3-E02 loan formulas (same as the API)', () {
    test('annuity 100.000.000, 12%, 12 months is 8.884.879', () {
      expect(
        annuityPayment(b(100000000), 1200, LoanFrequency.monthly, 12),
        b(8884879),
      );
      expect(annuityPayment(b(12000), 0, LoanFrequency.monthly, 12), b(1000));
      expect(annuityPayment(b(1000), 1200, LoanFrequency.monthly, 0), isNull);
    });

    test('periods step like the API and clamp to month end', () {
      expect(addPeriod('2026-01-31', LoanFrequency.monthly), '2026-02-28');
      expect(addPeriod('2026-11-30', LoanFrequency.quarterly), '2027-02-28');
      expect(addPeriod('2026-12-28', LoanFrequency.weekly), '2027-01-04');
      expect(addPeriod('2024-02-29', LoanFrequency.yearly), '2025-02-28');
      expect(
        periodsUntil('2026-11-01', '2027-10-01', LoanFrequency.monthly),
        12,
      );
      expect(
        periodsUntil('2026-11-01', '2026-10-01', LoanFrequency.monthly),
        0,
      );
    });

    test('rate text ↔ basis points', () {
      expect(parseRateBps('12'), 1200);
      expect(parseRateBps('9,5'), 950);
      expect(parseRateBps('9.75'), 975);
      expect(parseRateBps('9.755'), isNull);
      expect(parseRateBps('abc'), isNull);
      expect(formatRate(1200, ','), '12');
      expect(formatRate(950, ','), '9,5');
      expect(formatRate(975, '.'), '9.75');
    });
  });

  group('repositories', () {
    test('debt list, totals and repay map the API shapes', () async {
      final api = _Api({
        'personal-debts': {
          'items': [_debtJson()],
        },
        'personal-debts/summary': {
          'owedToMe': [],
          'iOwe': [],
          'totals': [
            {
              'currencyCode': 'VND',
              'receivableMinor': '2500000',
              'payableMinor': '2000000',
              'receivableCount': 2,
              'payableCount': 1,
            },
          ],
        },
        'personal-debts/d1/payments': _debtJson(),
      });
      final repo = DebtRepositoryImpl(api);
      final list = (await repo.list()).getOrElse(() => const []);
      expect(list.single.outstandingMinor, b(2000000));
      expect(list.single.direction, DebtDirection.lent);
      final totals = (await repo.totals()).getOrElse(() => const []);
      expect(totals.single.receivableMinor, b(2500000));
      await repo.repay(
        list.single,
        DebtRepay(
          clientId: 'r1',
          amountMinor: b(1000000),
          accountId: 'cash',
          paidOn: '2026-10-21',
        ),
      );
      expect(api.calls.last.$3, {
        'clientId': 'r1',
        'amountMinor': '1000000',
        'accountId': 'cash',
        'paidOn': '2026-10-21',
      });
    });

    test('loan payment sends both parts and no category', () async {
      final api = _Api({});
      final repo = LoanRepositoryImpl(api);
      await repo.pay(
        loan(),
        LoanPayment(
          clientId: 'p1',
          principalMinor: b(4400000),
          interestMinor: b(2100000),
          accountId: 'vcb',
          paidOn: '2026-10-21',
        ),
      );
      final body = api.calls.single.$3!;
      expect(body['amountMinor'], '6500000');
      expect(body['principalMinor'], '4400000');
      expect(body['interestMinor'], '2100000');
      expect(body.containsKey('principalCategoryId'), isFalse);
    });

    test('a debt transaction type is known (it used to break the list)', () {
      expect(TransactionType.values.byName('debt'), TransactionType.debt);
    });
  });

  group('use cases', () {
    test('a repayment above what is owed is refused before the API', () async {
      final cases = DefaultDebtUseCases(DebtRepositoryImpl(_Api({})));
      final result = await cases.repay(
        debt(),
        DebtRepay(
          clientId: 'r',
          amountMinor: b(2000001),
          accountId: 'cash',
          paidOn: '2026-10-21',
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('a due date before the lending day is refused', () async {
      final cases = DefaultDebtUseCases(DebtRepositoryImpl(_Api({})));
      final result = await cases.create(
        DebtDraft(
          clientId: 'c',
          direction: DebtDirection.lent,
          counterparty: 'Tuấn',
          amountMinor: b(1000),
          accountId: 'cash',
          occurredOn: '2026-10-12',
          dueDate: '2026-10-11',
        ),
      );
      expect(result.isLeft(), isTrue);
    });

    test('loan principal above what is owed is refused', () async {
      final cases = DefaultLoanUseCases(LoanRepositoryImpl(_Api({})));
      final result = await cases.pay(
        loan(outstanding: 1000),
        LoanPayment(
          clientId: 'p',
          principalMinor: b(1001),
          interestMinor: BigInt.zero,
          accountId: 'vcb',
          paidOn: '2026-10-21',
        ),
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('view model', () {
    test('open debts: newest first', () async {
      final h = await debtsApp(const SizedBox());
      await h.debtModel.load();
      expect(h.debtModel.owedToMe.map((d) => d.id), ['tuan', 'ha']);
      expect(h.debtModel.iOwe.map((d) => d.id), ['lan']);
      expect(h.debtModel.settled, hasLength(4));
      expect(h.debtModel.receivable, b(2500000));
      expect(h.debtModel.openCount, 3);
    });

    test('a repayment updates the debt and keeps its clientId', () async {
      final h = await debtsApp(const SizedBox());
      await h.debtModel.load();
      final saved = await h.debtModel.repay(
        h.debtModel.byId('tuan')!,
        DebtRepay(
          clientId: 'same',
          amountMinor: b(2000000),
          accountId: 'cash',
          paidOn: '2026-10-21',
        ),
      );
      expect(saved!.settled, isTrue);
      expect(h.debts.repaid.single.clientId, 'same');
      expect(h.debtModel.settled.first.id, 'tuan');
    });
  });
}
