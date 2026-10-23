import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'sync_item.dart';

abstract class SyncRepository {
  Future<List<SyncQueueItem>> read();
  Future<void> write(List<SyncQueueItem> items);

  /// When a batch was last accepted by the server; null before the first.
  Future<DateTime?> lastSyncedAt();
  Future<void> markSynced(DateTime at);

  /// Forgets the queue and the last sync time (sign-out).
  Future<void> clear();
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  );
}
