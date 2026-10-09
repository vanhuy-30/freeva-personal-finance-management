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
    expect(logger.messages, isEmpty);

    vault.value = 'secret-note 150000';
    expect(await repository.read(), isEmpty);
    expect(logger.messages.single, 'sync queue unreadable null');
    expect(logger.messages.single.contains('secret-note'), isFalse);
    expect(logger.messages.single.contains('150000'), isFalse);
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
