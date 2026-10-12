import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'sync_item.dart';
import 'sync_queue.dart';
import 'sync_repository.dart';

class SyncFlushOutcome {
  const SyncFlushOutcome({
    required this.items,
    this.schemaMismatch = false,
    this.syncFailed = false,
    this.duplicateHint = false,
    this.authError,
  });

  final List<SyncQueueItem> items;
  final bool schemaMismatch;
  final bool syncFailed;
  final bool duplicateHint;
  final AuthError? authError;
}

abstract class SyncUseCases {
  Future<List<SyncQueueItem>> load();
  Future<List<SyncQueueItem>> enqueue(SyncMutation mutation);
  Future<List<SyncQueueItem>> discard(String opId);
  Future<List<SyncQueueItem>> acknowledge({String? clientId, String? serverId});
  Future<SyncFlushOutcome> flush();
  Future<void> clear();
}

@LazySingleton(as: SyncUseCases)
class DefaultSyncUseCases implements SyncUseCases {
  DefaultSyncUseCases(this._repository);

  final SyncRepository _repository;
  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (_, _) {});
    return run;
  }

  @override
  Future<List<SyncQueueItem>> load() => _serialized(_repository.read);

  @override
  Future<List<SyncQueueItem>> enqueue(SyncMutation mutation) {
    return _serialized(() async {
      final current = await _repository.read();
      final next = coalesceQueue(current, _item(mutation));
      await _repository.write(next);
      return next;
    });
  }

  @override
  Future<List<SyncQueueItem>> discard(String opId) {
    return _serialized(() async {
      final next = (await _repository.read())
          .where((item) => item.opId != opId)
          .toList();
      await _repository.write(next);
      return next;
    });
  }

  @override
  Future<List<SyncQueueItem>> acknowledge({
    String? clientId,
    String? serverId,
  }) {
    return _serialized(() async {
      final next = (await _repository.read()).where((item) {
        if (serverId != null && item.serverId == serverId) return false;
        if (clientId != null &&
            item.action == SyncAction.create &&
            item.clientId == clientId) {
          return false;
        }
        return true;
      }).toList();
      await _repository.write(next);
      return next;
    });
  }

  @override
  Future<SyncFlushOutcome> flush() {
    return _serialized(() async {
      final current = await _repository.read();
      final batch = pendingSyncBatch(current);
      if (batch.isEmpty) {
        return SyncFlushOutcome(items: current);
      }
      final posted = await _repository.submit(batch);
      return posted.fold((failure) => _transport(current, batch, failure), (
        results,
      ) async {
        final next = applySyncResults(current, results);
        await _repository.write(next);
        return SyncFlushOutcome(
          items: next,
          syncFailed: results.any((result) => result.status == 'rejected'),
          duplicateHint: results.any((result) => result.duplicateHint),
        );
      });
    });
  }

  Future<SyncFlushOutcome> _transport(
    List<SyncQueueItem> current,
    List<SyncQueueItem> batch,
    AuthFailure failure,
  ) async {
    if (failure.code == AuthError.conflict) {
      return SyncFlushOutcome(items: current, schemaMismatch: true);
    }
    final opIds = batch.map((item) => item.opId).toSet();
    if (failure.code == AuthError.network ||
        failure.code == AuthError.unavailable) {
      final next = bumpSyncRetry(current, opIds);
      await _repository.write(next);
      return SyncFlushOutcome(
        items: next,
        syncFailed: true,
        authError: failure.code,
      );
    }
    if (failure.code == AuthError.invalidToken ||
        failure.code == AuthError.invalidInput) {
      final next = markSyncFailed(current, opIds);
      await _repository.write(next);
      return SyncFlushOutcome(
        items: next,
        syncFailed: true,
        authError: failure.code,
      );
    }
    return SyncFlushOutcome(items: current, authError: failure.code);
  }

  @override
  Future<void> clear() {
    return _serialized(() => _repository.write(const []));
  }

  SyncQueueItem _item(SyncMutation mutation) {
    return SyncQueueItem(
      opId: newSyncOpId(),
      clientId: mutation.clientId,
      serverId: mutation.serverId,
      action: mutation.action,
      type: mutation.type,
      occurredOn: mutation.occurredOn,
      categoryId: mutation.categoryId,
      notes: mutation.notes,
      legs: mutation.legs,
      rate: mutation.rate,
      quotedAt: mutation.quotedAt,
      version: mutation.version,
      createdAt: DateTime.now().toUtc(),
      retryCount: 0,
      status: SyncItemStatus.pending,
      review: false,
    );
  }
}
