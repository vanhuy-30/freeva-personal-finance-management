import '../../transactions/domain/transaction.dart';
import 'sync_item.dart';

/// The transaction a queued create or update describes, shaped like one read
/// from the server so the composer can edit it. Null when the item does not
/// carry enough to edit (a delete or restore, or a half-written item).
///
/// Leg client ids are kept as they are: sending the edit again must stay the
/// same transaction for the server (idempotency), not become a second one.
TransactionBundle? bundleFromQueueItem(SyncQueueItem item) {
  final type = item.type;
  final day = item.occurredOn;
  if (item.action != SyncAction.create && item.action != SyncAction.update) {
    return null;
  }
  if (type == null || day == null || item.legs.isEmpty) return null;
  final expected = type == TransactionType.transfer ? 2 : 1;
  if (item.legs.length != expected) return null;
  final legs = <TxLeg>[];
  for (final (index, leg) in item.legs.indexed) {
    final amount = BigInt.tryParse(leg.amountMinor);
    if (amount == null) return null;
    legs.add(
      TxLeg(
        // A queued create has no server id yet.
        id: index == 0
            ? (item.serverId ?? 'queued-${leg.clientId}')
            : 'queued-${leg.clientId}',
        clientId: leg.clientId,
        accountId: leg.accountId,
        currencyCode: leg.currencyCode,
        amountMinor: amount,
        type: type,
        occurredOn: day,
        occurredTime: item.occurredTime,
        categoryId: item.categoryId,
        notes: item.notes,
        merchant: item.merchant,
        tagIds: item.tagIds,
        transferGroupId: null,
        deletedAt: null,
        version: item.version ?? 1,
        createdAt: item.createdAt,
      ),
    );
  }
  final rate = item.rate;
  final quotedAt = item.quotedAt;
  return TransactionBundle(
    legs: legs,
    fx: rate != null && quotedAt != null
        ? TransactionFx(rate: rate, quotedAt: quotedAt)
        : null,
  );
}

/// Whether the person can fix this failed change by editing it: a create or
/// update the server refused because of its data, with enough kept to edit.
/// A missing target (`transactionMissing`), a delete, a restore, or a failure
/// that is not about the data (`unavailable`) cannot be fixed this way.
bool syncItemEditable(SyncQueueItem item) =>
    item.status == SyncItemStatus.failed &&
    const {
      SyncReason.invalid,
      SyncReason.categoryKind,
      SyncReason.walletMissing,
    }.contains(item.reason) &&
    bundleFromQueueItem(item) != null;
