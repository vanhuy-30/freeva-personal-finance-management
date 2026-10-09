import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_queue.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

void main() {
  test('coalesces offline edits without a second version', () {
    final created = _item(opId: 'create', version: null);
    final edited = coalesceQueue([
      created,
    ], _item(opId: 'edit', action: SyncAction.update, amount: '-2000'));
    expect(edited, hasLength(1));
    expect(edited.single.action, SyncAction.create);
    expect(edited.single.clientId, created.clientId);
    expect(edited.single.opId, 'create');
    expect(edited.single.legs.single.amountMinor, '-2000');

    expect(
      coalesceQueue([created], _item(opId: 'drop', action: SyncAction.delete)),
      isEmpty,
    );

    final update = _item(
      opId: 'update',
      action: SyncAction.update,
      serverId: 'server-1',
      version: 3,
    );
    final again = coalesceQueue(
      [update],
      _item(
        opId: 'again',
        action: SyncAction.update,
        serverId: 'server-1',
        version: 9,
        amount: '-3000',
      ),
    );
    expect(again.single.version, 3);
    expect(again.single.opId, 'update');
    expect(again.single.legs.single.amountMinor, '-3000');

    final deleted = coalesceQueue(
      [update],
      _item(
        opId: 'delete',
        action: SyncAction.delete,
        serverId: 'server-1',
        version: 9,
      ),
    );
    expect(deleted.single.action, SyncAction.delete);
    expect(deleted.single.version, 3);

    expect(
      coalesceQueue(
        [deleted.single],
        _item(
          opId: 'restore',
          action: SyncAction.restore,
          serverId: 'server-1',
          version: 3,
        ),
      ),
      isEmpty,
    );
  });

  test('maps sync results without dropping a conflict', () {
    final pending = [
      _item(opId: 'applied'),
      _item(opId: 'replayed', clientId: '22222222-2222-4222-8222-222222222222'),
      _item(opId: 'conflict', clientId: '33333333-3333-4333-8333-333333333333'),
      _item(opId: 'rejected', clientId: '44444444-4444-4444-8444-444444444444'),
      _item(opId: 'held', clientId: '55555555-5555-4555-8555-555555555555'),
    ];
    final next = applySyncResults(pending, const [
      SyncItemResult(
        opId: 'applied',
        status: 'applied',
        review: false,
        duplicateHint: true,
      ),
      SyncItemResult(
        opId: 'replayed',
        status: 'replayed',
        review: false,
        duplicateHint: false,
      ),
      SyncItemResult(
        opId: 'conflict',
        status: 'conflict',
        review: true,
        duplicateHint: false,
        serverUpdatedAt: null,
      ),
      SyncItemResult(
        opId: 'rejected',
        status: 'rejected',
        review: false,
        duplicateHint: false,
      ),
    ]);
    expect(next.map((item) => item.opId), ['conflict', 'rejected', 'held']);
    expect(next.first.status, SyncItemStatus.conflict);
    expect(next.first.review, isTrue);
    expect(next[1].status, SyncItemStatus.failed);
    expect(next.last.status, SyncItemStatus.pending);
  });

  test('sends at most 50 pending operations', () {
    final items = [
      _item(
        opId: 'conflict',
        clientId: '99999999-9999-4999-8999-999999999999',
        createdAt: DateTime.utc(2025, 1, 1),
        status: SyncItemStatus.conflict,
      ),
      for (var i = 0; i < 51; i++)
        _item(
          opId: 'op-$i',
          clientId: '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
          createdAt: DateTime.utc(2026, 1, 1, 0, i),
        ),
    ];
    final batch = pendingSyncBatch(items);
    expect(batch, hasLength(50));
    expect(
      batch.every((item) => item.status == SyncItemStatus.pending),
      isTrue,
    );
    expect(batch.map((item) => item.opId), isNot(contains('conflict')));
    expect(batch.map((item) => item.opId), isNot(contains('op-50')));
    expect(batch.first.opId, 'op-0');
  });
}

SyncQueueItem _item({
  required String opId,
  SyncAction action = SyncAction.create,
  String clientId = '11111111-1111-4111-8111-111111111111',
  String? serverId,
  int? version = 1,
  String amount = '-150000',
  DateTime? createdAt,
  SyncItemStatus status = SyncItemStatus.pending,
}) {
  return SyncQueueItem(
    opId: opId,
    clientId: clientId,
    serverId: serverId,
    action: action,
    type: TransactionType.expense,
    occurredOn: '2026-01-15',
    notes: 'secret-note',
    legs: [
      SyncLeg(
        clientId: clientId,
        accountId: 'card',
        currencyCode: 'VND',
        amountMinor: amount,
      ),
    ],
    version: version,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 15),
    retryCount: 0,
    status: status,
    review: false,
  );
}
