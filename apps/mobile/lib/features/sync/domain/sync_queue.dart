import 'dart:math';

import 'sync_item.dart';

String newSyncOpId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

List<SyncQueueItem> coalesceQueue(
  List<SyncQueueItem> items,
  SyncQueueItem incoming,
) {
  final pending = incoming.copyWith(
    status: SyncItemStatus.pending,
    review: false,
    retryCount: 0,
  );
  final create = _createFor(items, pending.clientId);
  if (pending.action == SyncAction.create) {
    if (create == null) return [...items, pending];
    return _replace(items, create, pending);
  }
  if (create != null &&
      (pending.action == SyncAction.update ||
          pending.action == SyncAction.delete)) {
    if (pending.action == SyncAction.delete) {
      return items.where((item) => item.opId != create.opId).toList();
    }
    return _replace(
      items,
      create,
      pending.copyWith(
        action: SyncAction.create,
        serverId: null,
        version: null,
      ),
    );
  }
  final serverId = pending.serverId;
  if (serverId == null) return [...items, pending];
  final related = items.where((item) => item.serverId == serverId).toList();
  if (related.isEmpty) return [...items, pending];
  final first = related.first;
  if (pending.action == SyncAction.restore &&
      first.action == SyncAction.delete &&
      first.status == SyncItemStatus.pending) {
    return items.where((item) => item.serverId != serverId).toList();
  }
  // Restore then delete before sending: the server copy is already deleted.
  if (pending.action == SyncAction.delete &&
      first.action == SyncAction.restore &&
      first.status == SyncItemStatus.pending) {
    return items.where((item) => item.serverId != serverId).toList();
  }
  return [
    ...items.where((item) => item.serverId != serverId),
    pending.copyWith(
      opId: first.opId,
      createdAt: first.createdAt,
      version: first.version ?? pending.version,
      serverUpdatedAt: first.serverUpdatedAt,
    ),
  ];
}

List<SyncQueueItem> applySyncResults(
  List<SyncQueueItem> items,
  List<SyncItemResult> results,
) {
  final byId = {for (final result in results) result.opId: result};
  final next = <SyncQueueItem>[];
  for (final item in items) {
    final result = byId[item.opId];
    if (result == null) {
      next.add(item);
      continue;
    }
    switch (result.status) {
      case 'applied':
      case 'replayed':
        break;
      case 'conflict':
        next.add(
          item.copyWith(
            status: SyncItemStatus.conflict,
            review: result.review,
            reason: SyncReason.changedElsewhere,
            server: result.server ?? item.server,
            serverUpdatedAt: result.serverUpdatedAt ?? item.serverUpdatedAt,
          ),
        );
      case 'rejected':
        next.add(
          item.copyWith(
            status: SyncItemStatus.failed,
            review: false,
            reason: reasonForCode(result.errorCode),
          ),
        );
      default:
        next.add(item);
    }
  }
  return next;
}

List<SyncQueueItem> bumpSyncRetry(
  List<SyncQueueItem> items,
  Set<String> opIds,
) {
  return [
    for (final item in items)
      if (opIds.contains(item.opId))
        item.copyWith(retryCount: item.retryCount + 1)
      else
        item,
  ];
}

List<SyncQueueItem> markSyncFailed(
  List<SyncQueueItem> items,
  Set<String> opIds,
) {
  return [
    for (final item in items)
      if (opIds.contains(item.opId))
        item.copyWith(
          status: SyncItemStatus.failed,
          review: false,
          reason: SyncReason.unavailable,
        )
      else
        item,
  ];
}

/// Puts a failed change back in line to be sent again.
List<SyncQueueItem> retrySyncItem(List<SyncQueueItem> items, String opId) {
  return [
    for (final item in items)
      if (item.opId == opId && item.status == SyncItemStatus.failed)
        item.copyWith(
          status: SyncItemStatus.pending,
          review: false,
          reason: null,
        )
      else
        item,
  ];
}

/// "Giữ bản trên máy này": sends the change again on top of the server's copy.
/// Edits, deletes and restores take the server's version; a create that clashed
/// with an existing transaction becomes an edit of that transaction. Does
/// nothing without the server copy.
List<SyncQueueItem> keepLocalSyncItem(List<SyncQueueItem> items, String opId) {
  return [
    for (final item in items)
      if (item.opId == opId &&
          item.status == SyncItemStatus.conflict &&
          item.server != null)
        item.copyWith(
          status: SyncItemStatus.pending,
          review: false,
          reason: null,
          version: item.server!.version,
          action: item.action == SyncAction.create
              ? SyncAction.update
              : item.action,
          serverId: item.action == SyncAction.create
              ? item.server!.id
              : item.serverId,
          server: null,
        )
      else
        item,
  ];
}

/// One short reason for a rejected change, from the server's item code.
SyncReason reasonForCode(String? code) => switch (code) {
  'ACCOUNT_NOT_FOUND' => SyncReason.walletMissing,
  'TRANSACTION_NOT_FOUND' => SyncReason.transactionMissing,
  'VALIDATION_ERROR' => SyncReason.invalid,
  'CATEGORY_KIND_MISMATCH' => SyncReason.categoryKind,
  _ => SyncReason.unavailable,
};

List<SyncQueueItem> pendingSyncBatch(List<SyncQueueItem> items) {
  final pending = items.where((item) => item.status == SyncItemStatus.pending);
  final ordered = pending.toList()
    ..sort((a, b) {
      final time = a.createdAt.compareTo(b.createdAt);
      return time != 0 ? time : a.opId.compareTo(b.opId);
    });
  if (ordered.length <= syncBatchLimit) return ordered;
  return ordered.sublist(0, syncBatchLimit);
}

SyncQueueItem? _createFor(List<SyncQueueItem> items, String clientId) {
  for (final item in items) {
    if (item.action == SyncAction.create && item.clientId == clientId) {
      return item;
    }
  }
  return null;
}

List<SyncQueueItem> _replace(
  List<SyncQueueItem> items,
  SyncQueueItem existing,
  SyncQueueItem incoming,
) {
  final kept = incoming.copyWith(
    opId: existing.opId,
    createdAt: existing.createdAt,
    serverUpdatedAt: existing.serverUpdatedAt,
  );
  return [
    for (final item in items)
      if (item.opId == existing.opId) kept else item,
  ];
}
