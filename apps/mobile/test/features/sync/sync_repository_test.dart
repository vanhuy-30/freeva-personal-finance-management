import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/logging/app_logger.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/sync/data/sync_queue_vault.dart';
import 'package:mobile/features/sync/data/sync_repository_impl.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

void main() {
  test('stores integer amounts and does not log notes', () async {
    final vault = _Vault();
    final logger = _Logger();
    final api = _Api();
    final repository = SyncRepositoryImpl(api, vault, logger);
    final item = SyncQueueItem(
      opId: '11111111-1111-4111-8111-111111111111',
      clientId: '22222222-2222-4222-8222-222222222222',
      action: SyncAction.create,
      type: TransactionType.expense,
      occurredOn: '2026-01-15',
      notes: 'secret-note',
      legs: const [
        SyncLeg(
          clientId: '22222222-2222-4222-8222-222222222222',
          accountId: 'card',
          currencyCode: 'VND',
          amountMinor: '-150000',
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 15),
      retryCount: 0,
      status: SyncItemStatus.pending,
      review: false,
    );
    await repository.write([item]);
    final stored = jsonDecode(vault.value!) as Map<String, dynamic>;
    final leg = ((stored['items'] as List).first as Map)['legs'] as List;
    expect((leg.first as Map)['amountMinor'], '-150000');
    expect((leg.first as Map)['amountMinor'], isA<String>());

    final read = await repository.read();
    expect(read.single.notes, 'secret-note');
    expect(read.single.legs.single.amountMinor, '-150000');

    api.body = {
      'results': [
        {
          'opId': item.opId,
          'status': 'applied',
          'review': false,
          'transaction': null,
          'error': null,
          'duplicates': [
            {
              'id': 'server-id',
              'clientId': '33333333-3333-4333-8333-333333333333',
            },
          ],
        },
      ],
    };
    final posted = await repository.submit([item]);
    expect(posted.getOrElse(() => const []).single.duplicateHint, isTrue);
    expect(api.sent?['schemaVersion'], 1);
    expect(
      api.sent?['operations'][0]['body']['legs'][0]['amountMinor'],
      '-150000',
    );
    expect(api.sent?['operations'][0]['body']['merchant'], isNull);
    expect(api.sent?['operations'][0]['body']['tagIds'], isEmpty);
    expect(logger.messages, isEmpty);

    vault.value = 'secret-note 150000';
    expect(await repository.read(), isEmpty);
    expect(logger.messages.single, 'sync queue unreadable null');
    expect(logger.messages.single.contains('secret-note'), isFalse);
    expect(logger.messages.single.contains('150000'), isFalse);
  });

  test(
    'keeps why a change is held and when the server last answered',
    () async {
      final vault = _Vault();
      final repository = SyncRepositoryImpl(_Api(), vault, _Logger());
      final item = SyncQueueItem(
        opId: '11111111-1111-4111-8111-111111111111',
        clientId: '22222222-2222-4222-8222-222222222222',
        action: SyncAction.update,
        createdAt: DateTime.utc(2026, 1, 15),
        retryCount: 0,
        status: SyncItemStatus.failed,
        review: false,
        reason: SyncReason.walletMissing,
      );
      expect(await repository.lastSyncedAt(), isNull);
      await repository.write([item]);
      await repository.markSynced(DateTime.utc(2026, 10, 22, 9, 30));
      expect((await repository.read()).single.reason, SyncReason.walletMissing);
      expect(
        await repository.lastSyncedAt(),
        DateTime.utc(2026, 10, 22, 9, 30),
      );
      // An empty queue still remembers the time; sign-out forgets both.
      await repository.write(const []);
      expect(await repository.read(), isEmpty);
      expect(
        await repository.lastSyncedAt(),
        DateTime.utc(2026, 10, 22, 9, 30),
      );
      await repository.clear();
      expect(vault.value, isNull);
      expect(await repository.lastSyncedAt(), isNull);
    },
  );

  test(
    'stores the server copy and reads a conflict with its duplicates',
    () async {
      final vault = _Vault();
      final api = _Api();
      final repository = SyncRepositoryImpl(api, vault, _Logger());
      final leg = {
        'id': 'srv-1',
        'clientId': 'c1',
        'accountId': 'cash',
        'currencyCode': 'VND',
        'amountMinor': '-60000',
        'type': 'expense',
        'occurredOn': '2026-10-22',
        'categoryId': 'food',
        'notes': 'bún',
        'merchant': 'Phở Thìn',
        'version': 4,
        'updatedAt': '2026-10-22T05:50:00.000Z',
      };
      api.body = {
        'results': [
          {
            'opId': 'a',
            'status': 'conflict',
            'review': true,
            'transaction': {
              'legs': [leg],
            },
            'error': {'code': 'TRANSACTION_CONFLICT'},
            'duplicates': <Object>[],
          },
          {
            'opId': 'b',
            'status': 'applied',
            'review': false,
            'transaction': {
              'legs': [leg],
            },
            'duplicates': [
              {'id': 'old-1', 'clientId': 'c0'},
            ],
          },
        ],
      };
      final results = (await repository.submit(const [])).getOrElse(() => []);
      expect(results[0].server?.version, 4);
      expect(results[0].server?.merchant, 'Phở Thìn');
      expect(results[0].server?.updatedAt, DateTime.utc(2026, 10, 22, 5, 50));
      expect(results[1].server, isNull);
      expect(results[1].transactionId, 'srv-1');
      expect(results[1].duplicateIds, ['old-1']);
      final item = SyncQueueItem(
        opId: '11111111-1111-4111-8111-111111111111',
        clientId: '22222222-2222-4222-8222-222222222222',
        action: SyncAction.update,
        createdAt: DateTime.utc(2026, 1, 15),
        retryCount: 0,
        status: SyncItemStatus.conflict,
        review: true,
        server: results[0].server,
      );
      await repository.write([item]);
      final back = (await repository.read()).single.server!;
      expect((back.id, back.version, back.amountMinor), ('srv-1', 4, '-60000'));
      expect(back.categoryId, 'food');
    },
  );

  test('legacy queue without merchant or tagIds still loads', () async {
    final vault = _Vault();
    final repository = SyncRepositoryImpl(_Api(), vault, _Logger());
    vault.value = jsonEncode({
      'items': [
        {
          'opId': '11111111-1111-4111-8111-111111111111',
          'clientId': '22222222-2222-4222-8222-222222222222',
          'serverId': null,
          'action': 'create',
          'type': 'expense',
          'occurredOn': '2026-01-15',
          'categoryId': 'food',
          'notes': 'secret-note',
          'legs': [
            {
              'clientId': '22222222-2222-4222-8222-222222222222',
              'accountId': 'card',
              'currencyCode': 'VND',
              'amountMinor': '-150000',
            },
          ],
          'rate': null,
          'quotedAt': null,
          'version': null,
          'createdAt': '2026-01-15T00:00:00.000Z',
          'serverUpdatedAt': null,
          'retryCount': 0,
          'status': 'pending',
          'review': false,
        },
      ],
    });
    final items = await repository.read();
    expect(items, hasLength(1));
    expect(items.single.merchant, isNull);
    expect(items.single.tagIds, isEmpty);
    expect(items.single.notes, 'secret-note');
  });
}

class _Vault implements SyncQueueVault {
  String? value;

  @override
  Future<void> delete() async => value = null;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;
}

class _Logger implements AppLogger {
  final messages = <String>[];

  @override
  void debug(String message) => messages.add(message);

  @override
  void info(String message) => messages.add(message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    messages.add('$message $error');
  }

  @override
  void op(String message) => messages.add(message);

  @override
  void http(String message) => messages.add(message);
}

class _Api implements AuthorizedApi {
  Map<String, dynamic>? sent;
  Map<String, dynamic> body = const {};

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    sent = body;
    return right(this.body);
  }
}
