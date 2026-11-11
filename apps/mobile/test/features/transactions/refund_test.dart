import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';

import '../home/fixtures.dart' show b;
import 'c1_stub.dart' show tx;
import '../../support/server_config_fixture.dart';

/// MOB-P3-008: refund parsing, request shapes and the cap.
void main() {
  late _Api api;
  late TransactionRepositoryImpl repository;
  late DefaultTransactionUseCases cases;
  setUp(() {
    api = _Api();
    repository = TransactionRepositoryImpl(api);
    cases = DefaultTransactionUseCases(repository, testServerConfigModel());
  });

  test(
    'list reads refund rows and refundedMinor, skips unknown types',
    () async {
      api.answer = {
        'items': [
          _leg('e', 'expense', '-890000', refunded: '300000'),
          _leg('r', 'refund', '300000', refundOf: 'e'),
          _leg('x', 'something_new', '1'),
        ],
        'page': 1,
        'total': 3,
      };
      final page = (await repository.list(const TransactionQuery()))
          .getOrElse(() => throw StateError('failed'));
      expect(page.legs.map((l) => l.id), ['e', 'r']);
      expect(page.legs.first.refundedMinor, b(300000));
      expect(page.legs.last.type, TransactionType.refund);
      expect(page.legs.last.refundOfId, 'e');
      expect(page.legs.last.refundedMinor, isNull);
    },
  );

  test(
    'refund posts to the expense with the clientId as Idempotency-Key',
    () async {
      api.answer = {
        'legs': [_leg('r', 'refund', '300000', refundOf: 'e')],
        'fx': null,
      };
      await repository.refund(
        'e',
        RefundCommand(
          clientId: 'k-1',
          accountId: 'cash',
          amountMinor: b(300000),
          occurredOn: '2026-10-21',
        ),
      );
      final call = api.calls.single;
      expect(call.method, 'POST');
      expect(call.path, 'transactions/e/refunds');
      expect(call.headers, {'Idempotency-Key': 'k-1'});
      expect(call.body, {
        'clientId': 'k-1',
        'accountId': 'cash',
        'amountMinor': '300000',
        'occurredOn': '2026-10-21',
      });
    },
  );

  test('delete sends the refunds choice only when given', () async {
    await repository.remove('e', 3);
    await repository.remove('e', 3, refunds: RefundDisposition.keep);
    expect(api.calls.map((c) => c.path), [
      'transactions/e?version=3',
      'transactions/e?version=3&refunds=keep',
    ]);
  });

  group('refundable', () {
    TransactionBundle expense({int? refunded, bool deleted = false}) =>
        TransactionBundle(
          legs: [
            tx(
              'e',
              account: 'cash',
              amount: -890000,
              refunded: refunded,
              deleted: deleted,
            ),
          ],
        );

    test('is the amount minus refunds, never below zero', () {
      expect(expense().refundable, b(890000));
      expect(expense(refunded: 300000).refundable, b(590000));
      expect(expense(refunded: 890000).refundable, BigInt.zero);
      expect(expense(deleted: true).refundable, BigInt.zero);
      final income = TransactionBundle(
        legs: [
          tx('i', account: 'cash', amount: 1000, type: TransactionType.income),
        ],
      );
      expect(income.refundable, BigInt.zero);
    });

    test(
      'use case refuses more than what is left without calling the API',
      () async {
        final result = await cases.refund(
          expense(refunded: 300000),
          RefundCommand(
            clientId: 'k',
            accountId: 'cash',
            amountMinor: b(590001),
            occurredOn: '2026-10-21',
          ),
        );
        expect(
          result.fold((f) => f.code, (_) => null),
          AuthError.refundExceeds,
        );
        expect(api.calls, isEmpty);
      },
    );
  });
}

class _Api implements AuthorizedApi {
  final calls =
      <
        ({
          String method,
          String path,
          Map<String, dynamic>? body,
          Map<String, String>? headers,
        })
      >[];
  Map<String, dynamic> answer = {};

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body, headers: headers));
    return right(answer);
  }
}

Map<String, dynamic> _leg(
  String id,
  String type,
  String amount, {
  String? refunded,
  String? refundOf,
}) => {
  'id': id,
  'clientId': 'c-$id',
  'accountId': 'cash',
  'currencyCode': 'VND',
  'amountMinor': amount,
  'type': type,
  'occurredOn': '2026-10-12',
  'occurredTime': null,
  'categoryId': 'shopping',
  'notes': null,
  'merchant': null,
  'tagIds': <String>[],
  'transferGroupId': null,
  'refundOfId': refundOf,
  'refundedMinor': refunded,
  'fxQuoteId': null,
  'deletedAt': null,
  'version': 1,
  'createdAt': '2026-10-12T00:00:00.000Z',
  'updatedAt': '2026-10-12T00:00:00.000Z',
};
