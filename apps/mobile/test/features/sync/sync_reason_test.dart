import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_queue.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_labels.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_mark_chip.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_marks.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

void main() {
  test('server codes become one short reason each', () {
    expect(reasonForCode('ACCOUNT_NOT_FOUND'), SyncReason.walletMissing);
    expect(
      reasonForCode('TRANSACTION_NOT_FOUND'),
      SyncReason.transactionMissing,
    );
    expect(reasonForCode('VALIDATION_ERROR'), SyncReason.invalid);
    expect(reasonForCode('TRANSACTIONS_UNAVAILABLE'), SyncReason.unavailable);
    expect(reasonForCode(null), SyncReason.unavailable);
  });

  test('results keep why a change is held', () {
    final next = applySyncResults(
      [syncItem('c'), syncItem('r')],
      const [
        SyncItemResult(
          opId: 'c',
          status: 'conflict',
          review: false,
          duplicateHint: false,
        ),
        SyncItemResult(
          opId: 'r',
          status: 'rejected',
          review: false,
          duplicateHint: false,
          errorCode: 'ACCOUNT_NOT_FOUND',
        ),
      ],
    );
    expect(next[0].reason, SyncReason.changedElsewhere);
    expect(next[1].reason, SyncReason.walletMissing);
  });

  test('retry puts only a failed change back in line', () {
    final items = [
      syncItem(
        'f',
        status: SyncItemStatus.failed,
        reason: SyncReason.unavailable,
      ),
      syncItem(
        'c',
        status: SyncItemStatus.conflict,
        reason: SyncReason.changedElsewhere,
      ),
    ];
    final next = retrySyncItem(items, 'f');
    expect(next[0].status, SyncItemStatus.pending);
    expect(next[0].reason, isNull);
    expect(retrySyncItem(items, 'c')[1].status, SyncItemStatus.conflict);
  });

  test('trying again is offered only when the data is not the problem', () {
    bool can(SyncReason? r, [SyncItemStatus s = SyncItemStatus.failed]) =>
        syncCanRetry(syncItem('x', status: s, reason: r));
    expect(can(SyncReason.unavailable), isTrue);
    expect(can(null), isTrue);
    expect(can(SyncReason.invalid), isFalse);
    expect(can(SyncReason.walletMissing), isFalse);
    expect(can(SyncReason.changedElsewhere, SyncItemStatus.conflict), isFalse);
  });

  test('a row is marked by its queued change; attention wins over waiting', () {
    final row = canvasRows().first;
    final id = row.id;
    expect(syncMarkFor([], row), isNull);
    expect(
      syncMarkFor([
        syncItem('a', action: SyncAction.update, serverId: id),
      ], row),
      SyncMark.waiting,
    );
    expect(
      syncMarkFor([
        syncItem('a', action: SyncAction.update, serverId: id),
        syncItem(
          'b',
          action: SyncAction.delete,
          serverId: id,
          status: SyncItemStatus.failed,
        ),
      ], row),
      SyncMark.review,
    );
    expect(syncMarkFor([syncItem('z', serverId: 'other')], row), isNull);
    expect(row.type, isA<TransactionType>());
  });
}
