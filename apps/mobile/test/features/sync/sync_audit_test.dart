import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_queue.dart';
import 'package:mobile/features/sync/domain/sync_repository.dart';
import 'package:mobile/features/sync/domain/sync_use_cases.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import '../auth/fakes.dart';
import '../transactions/transaction_view_model_test.dart';

// QA-P2-001: contract audit of docs/architecture/mobile-sync.md.
void main() {
  test('restore then delete before sending leaves nothing to send', () {
    final restore = _item('restore', SyncAction.restore, serverId: 's1');
    final next = coalesceQueue([
      restore,
    ], _item('del', SyncAction.delete, serverId: 's1'));
    expect(next, isEmpty);
  });

  test('editing a conflicted change keeps its old version', () {
    final conflict = _item(
      'conflict',
      SyncAction.update,
      serverId: 's1',
      version: 3,
      status: SyncItemStatus.conflict,
    );
    final next = coalesceQueue([
      conflict,
    ], _item('edit', SyncAction.update, serverId: 's1', version: 9));
    expect(next.single.version, 3);
    expect(next.single.status, SyncItemStatus.pending);
  });

  test('a second create with the same clientId stays one item', () {
    final first = _item('a', SyncAction.create);
    final next = coalesceQueue([first], _item('b', SyncAction.create));
    expect(next, hasLength(1));
    expect(next.single.opId, 'a');
  });

  test('replayed create leaves the queue', () {
    final next = applySyncResults(
      [_item('a', SyncAction.create)],
      const [
        SyncItemResult(
          opId: 'a',
          status: 'replayed',
          review: false,
          duplicateHint: false,
        ),
      ],
    );
    expect(next, isEmpty);
  });

  test(
    'queue left behind while signed out is cleared once auth is ready',
    () async {
      final auth = DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )..stage = AuthStage.signedOut;
      final repository = _Repository([_item('left', SyncAction.create)]);
      final model = DefaultSyncViewModel(
        DefaultSyncUseCases(repository),
        auth,
        RecordingAnalytics(),
      );
      // Cold start: auth has not read the session yet, so keep the queue.
      await Future<void>.delayed(Duration.zero);
      expect(repository.items, hasLength(1));

      auth
        ..ready = true
        ..notifyListeners();
      await Future<void>.delayed(Duration.zero);
      expect(repository.items, isEmpty);
      model.dispose();
      auth.dispose();
    },
  );

  test('queue is kept when auth restores a session', () async {
    final auth = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
    )..stage = AuthStage.signedOut;
    final repository = _Repository([_item('keep', SyncAction.create)]);
    final model = DefaultSyncViewModel(
      DefaultSyncUseCases(repository),
      auth,
      RecordingAnalytics(),
    );
    auth
      ..stage = AuthStage.locked
      ..ready = true
      ..notifyListeners();
    await Future<void>.delayed(Duration.zero);
    expect(repository.items, hasLength(1));
    model.dispose();
    auth.dispose();
  });
}

SyncQueueItem _item(
  String opId,
  SyncAction action, {
  String? serverId,
  int? version = 1,
  SyncItemStatus status = SyncItemStatus.pending,
}) {
  const clientId = '11111111-1111-4111-8111-111111111111';
  return SyncQueueItem(
    opId: opId,
    clientId: clientId,
    serverId: serverId,
    action: action,
    type: TransactionType.expense,
    occurredOn: '2026-01-15',
    legs: const [
      SyncLeg(
        clientId: clientId,
        accountId: 'card',
        currencyCode: 'VND',
        amountMinor: '-150000',
      ),
    ],
    version: version,
    createdAt: DateTime.utc(2026, 1, 15),
    retryCount: 0,
    status: status,
    review: false,
  );
}

class _Repository implements SyncRepository {
  _Repository(this.items);

  List<SyncQueueItem> items;

  @override
  Future<List<SyncQueueItem>> read() async => items;
  @override
  Future<void> write(List<SyncQueueItem> value) async => items = value;
  @override
  Future<DateTime?> lastSyncedAt() async => null;
  @override
  Future<void> markSynced(DateTime at) async {}
  @override
  Future<void> clear() async => items = const [];
  @override
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  ) async => right(const []);
}
