import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_queue.dart';

import 'sync_fakes.dart';

void main() {
  const copy = SyncServerCopy(
    id: 'srv-9',
    version: 7,
    occurredOn: '2026-10-22',
    amountMinor: '-60000',
    currencyCode: 'VND',
  );
  SyncQueueItem conflict(SyncAction action, {String? serverId}) =>
      syncItem('x', action: action, serverId: serverId).copyWith(
        status: SyncItemStatus.conflict,
        reason: SyncReason.changedElsewhere,
        version: 3,
        server: copy,
      );

  test('an edit, a delete and a restore go again on the server version', () {
    for (final action in [
      SyncAction.update,
      SyncAction.delete,
      SyncAction.restore,
    ]) {
      final next = keepLocalSyncItem([
        conflict(action, serverId: 'srv-9'),
      ], 'x');
      expect(next.single.status, SyncItemStatus.pending, reason: '$action');
      expect(next.single.version, 7);
      expect(next.single.action, action);
      expect(next.single.reason, isNull);
      expect(next.single.server, isNull);
    }
  });

  test(
    'a create that clashed becomes an edit of the transaction already there',
    () {
      final next = keepLocalSyncItem([conflict(SyncAction.create)], 'x');
      expect(next.single.action, SyncAction.update);
      expect(next.single.serverId, 'srv-9');
      expect(next.single.version, 7);
    },
  );

  test('nothing changes without a conflict or without the server copy', () {
    final pending = syncItem('x');
    expect(
      keepLocalSyncItem([pending], 'x').single.status,
      SyncItemStatus.pending,
    );
    final noCopy = syncItem('x').copyWith(status: SyncItemStatus.conflict);
    expect(keepLocalSyncItem([noCopy], 'x').single.version, isNull);
    expect(
      keepLocalSyncItem([conflict(SyncAction.update)], 'other').single.status,
      SyncItemStatus.conflict,
    );
  });

  test('a conflict keeps the server copy that came with it', () {
    final next = applySyncResults(
      [syncItem('x', action: SyncAction.update, serverId: 'srv-9')],
      const [
        SyncItemResult(
          opId: 'x',
          status: 'conflict',
          review: true,
          duplicateHint: false,
          server: copy,
        ),
      ],
    );
    expect(next.single.server?.version, 7);
  });
}
