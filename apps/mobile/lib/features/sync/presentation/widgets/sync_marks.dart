import '../../../transactions/domain/transaction.dart';
import '../../domain/sync_item.dart';
import 'sync_mark_chip.dart';

/// The mark a list row carries for its queued change: [SyncMark.review] when
/// the change needs the person, [SyncMark.waiting] when it only waits to be
/// sent, null when nothing is queued for the transaction.
SyncMark? syncMarkFor(List<SyncQueueItem> items, TransactionBundle row) {
  final clientIds = {for (final leg in row.legs) leg.clientId};
  SyncMark? found;
  for (final item in items) {
    final same =
        item.serverId == row.id ||
        (item.action == SyncAction.create && clientIds.contains(item.clientId));
    if (!same) continue;
    if (item.status != SyncItemStatus.pending) return SyncMark.review;
    found = SyncMark.waiting;
  }
  return found;
}
