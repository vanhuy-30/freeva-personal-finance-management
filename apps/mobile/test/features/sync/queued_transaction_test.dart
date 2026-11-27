import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sync/domain/queued_transaction.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import 'sync_fakes.dart';

SyncQueueItem item({
  SyncAction action = SyncAction.create,
  SyncItemStatus status = SyncItemStatus.failed,
  SyncReason? reason = SyncReason.invalid,
  TransactionType? type = TransactionType.expense,
  String? serverId,
  int? version,
  List<SyncLeg>? legs,
  String? occurredOn = '2026-10-22',
  String? rate,
  String? quotedAt,
}) => SyncQueueItem(
  opId: 'op',
  clientId: 'c1',
  serverId: serverId,
  version: version,
  action: action,
  type: type,
  occurredOn: occurredOn,
  occurredTime: '09:15',
  categoryId: 'food',
  notes: 'ghi chú',
  merchant: 'Phở',
  tagIds: const ['t1'],
  legs:
      legs ??
      const [
        SyncLeg(
          clientId: 'c1',
          accountId: 'cash',
          currencyCode: 'VND',
          amountMinor: '-65000',
        ),
      ],
  rate: rate,
  quotedAt: quotedAt,
  createdAt: DateTime.utc(2026, 10, 22, 9),
  retryCount: 0,
  status: status,
  review: false,
  reason: reason,
);

void main() {
  group('bundleFromQueueItem', () {
    test('rebuilds the transaction with the queued ids and values', () {
      final bundle = bundleFromQueueItem(item())!;
      final leg = bundle.legs.single;
      expect(bundle.type, TransactionType.expense);
      expect(leg.clientId, 'c1');
      expect(leg.accountId, 'cash');
      expect(leg.amountMinor, BigInt.from(-65000));
      expect(bundle.occurredOn, '2026-10-22');
      expect(bundle.occurredTime, '09:15');
      expect(bundle.categoryId, 'food');
      expect(bundle.notes, 'ghi chú');
      expect(bundle.merchant, 'Phở');
      expect(bundle.tagIds, ['t1']);
      expect(bundle.deleted, isFalse);
      expect(bundle.fx, isNull);
      // A queued create has no server id; the composer must not take it for one.
      expect(bundle.id, 'queued-c1');
      expect(bundle.version, 1);
    });

    test('an update keeps the server id and the queued version', () {
      final bundle = bundleFromQueueItem(
        item(action: SyncAction.update, serverId: 'srv-1', version: 4),
      )!;
      expect(bundle.id, 'srv-1');
      expect(bundle.version, 4);
    });

    test('a transfer has both legs and its rate', () {
      final bundle = bundleFromQueueItem(
        item(
          type: TransactionType.transfer,
          legs: const [
            SyncLeg(
              clientId: 'c1',
              accountId: 'cash',
              currencyCode: 'VND',
              amountMinor: '-250000',
            ),
            SyncLeg(
              clientId: 'c2',
              accountId: 'usd',
              currencyCode: 'USD',
              amountMinor: '1000',
            ),
          ],
          rate: '0.004',
          quotedAt: '2026-10-22T02:00:00Z',
        ),
      )!;
      expect(bundle.legs.map((l) => l.clientId), ['c1', 'c2']);
      expect(bundle.legs.map((l) => l.accountId), ['cash', 'usd']);
      expect(bundle.fx?.rate, '0.004');
      expect(bundle.fx?.quotedAt, '2026-10-22T02:00:00Z');
    });

    test('a delete, a restore or a half-written item has nothing to edit', () {
      expect(bundleFromQueueItem(item(action: SyncAction.delete)), isNull);
      expect(bundleFromQueueItem(item(action: SyncAction.restore)), isNull);
      expect(bundleFromQueueItem(item(type: null)), isNull);
      expect(bundleFromQueueItem(item(occurredOn: null)), isNull);
      expect(bundleFromQueueItem(item(legs: const [])), isNull);
      // A transfer needs two legs.
      expect(bundleFromQueueItem(item(type: TransactionType.transfer)), isNull);
      expect(
        bundleFromQueueItem(
          item(
            legs: const [
              SyncLeg(
                clientId: 'c1',
                accountId: 'cash',
                currencyCode: 'VND',
                amountMinor: 'abc',
              ),
            ],
          ),
        ),
        isNull,
      );
    });
  });

  group('syncItemEditable', () {
    test('only data the server refused can be fixed by editing', () {
      for (final reason in [
        SyncReason.invalid,
        SyncReason.categoryKind,
        SyncReason.walletMissing,
      ]) {
        expect(
          syncItemEditable(item(reason: reason)),
          isTrue,
          reason: '$reason',
        );
        expect(
          syncItemEditable(
            item(action: SyncAction.update, serverId: 's', reason: reason),
          ),
          isTrue,
        );
      }
      for (final reason in [
        SyncReason.unavailable,
        SyncReason.transactionMissing,
        SyncReason.changedElsewhere,
        null,
      ]) {
        expect(
          syncItemEditable(item(reason: reason)),
          isFalse,
          reason: '$reason',
        );
      }
    });

    test('not a pending item, a conflict, a delete or a restore', () {
      expect(
        syncItemEditable(item(status: SyncItemStatus.pending, reason: null)),
        isFalse,
      );
      expect(syncItemEditable(item(status: SyncItemStatus.conflict)), isFalse);
      expect(syncItemEditable(item(action: SyncAction.delete)), isFalse);
      expect(syncItemEditable(item(action: SyncAction.restore)), isFalse);
    });

    test('works on the shared test item too', () {
      final shared = syncItem(
        'x',
        status: SyncItemStatus.failed,
        reason: SyncReason.invalid,
      );
      expect(syncItemEditable(shared), isTrue);
    });
  });
}
