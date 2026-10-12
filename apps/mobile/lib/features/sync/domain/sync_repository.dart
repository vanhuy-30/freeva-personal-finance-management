import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'sync_item.dart';

abstract class SyncRepository {
  Future<List<SyncQueueItem>> read();
  Future<void> write(List<SyncQueueItem> items);
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  );
}
