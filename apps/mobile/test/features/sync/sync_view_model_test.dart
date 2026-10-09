import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_repository.dart';
import 'package:mobile/features/sync/domain/sync_use_cases.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

import '../auth/fakes.dart';
import '../transactions/transaction_view_model_test.dart';

void main() {
  late DefaultAuthViewModel auth;
  late RecordingAnalytics analytics;

  setUp(() {
    analytics = RecordingAnalytics();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
  });

  tearDown(() => auth.dispose());

  test('network retry and rejection do not record amounts', () async {
    final repository = _Repository([_item('one')]);
    final model = _model(repository, auth, analytics);
    repository.failure = const AuthFailure(AuthError.network);
    await model.flush();
    expect(model.items.single.retryCount, 1);
    expect(model.items.single.status, SyncItemStatus.pending);
    expect(analytics.events.single['event'], 'sync_failed');
    expect(analytics.events.single.containsKey('notes'), isFalse);
    expect('${analytics.events}', isNot(contains('secret-note')));
    expect('${analytics.events}', isNot(contains('150000')));

    repository.failure = null;
    repository.results = [
      const SyncItemResult(
        opId: 'one',
        status: 'rejected',
        review: false,
        duplicateHint: false,
      ),
    ];
    await model.flush();
    expect(model.items.single.status, SyncItemStatus.failed);
    expect(analytics.events, hasLength(2));
    model.dispose();
  });

  test(
    'conflict is kept and schema mismatch does not clear the queue',
    () async {
      final repository = _Repository([_item('one')]);
      final model = _model(repository, auth, analytics);
      repository.results = [
        SyncItemResult(
          opId: 'one',
          status: 'conflict',
          review: true,
          duplicateHint: false,
          serverUpdatedAt: DateTime.utc(2026, 1, 16),
        ),
      ];
      await model.flush();
      expect(model.items.single.status, SyncItemStatus.conflict);
      expect(model.items.single.review, isTrue);
      expect(model.items.single.serverUpdatedAt, DateTime.utc(2026, 1, 16));
      expect(analytics.events, isEmpty);

      repository.failure = const AuthFailure(AuthError.conflict);
      repository.items = [_item('two')];
      model.items = repository.items;
      await model.flush();
      expect(model.schemaMismatch, isTrue);
      expect(model.items, hasLength(1));
      expect(analytics.events, isEmpty);
      model.dispose();
    },
  );

  test(
    'applied and replayed leave the queue and a batch stops at 50',
    () async {
      final queued = [
        for (var i = 0; i < 51; i++)
          _item(
            'op-$i',
            clientId:
                '00000000-0000-4000-8000-${i.toString().padLeft(12, '0')}',
            createdAt: DateTime.utc(2026, 1, 1, 0, i),
          ),
      ];
      final repository = _Repository(queued);
      final model = _model(repository, auth, analytics);
      await model.flush();
      expect(repository.batches.single, hasLength(50));
      expect(model.items.single.opId, 'op-50');

      repository.results = [
        const SyncItemResult(
          opId: 'op-50',
          status: 'replayed',
          review: false,
          duplicateHint: true,
        ),
      ];
      await model.flush();
      expect(model.items, isEmpty);
      expect(model.duplicateHint, isTrue);
      expect('${analytics.events}', isNot(contains('op-50')));
      model.dispose();
    },
  );

  test('sign-out clears the queue and lock keeps it', () async {
    final repository = _Repository(const []);
    repository.results = const [];
    final model = _model(repository, auth, analytics);
    await model.enqueue(
      const SyncMutation(
        action: SyncAction.create,
        clientId: '11111111-1111-4111-8111-111111111111',
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        notes: 'secret-note',
        legs: [
          SyncLeg(
            clientId: '11111111-1111-4111-8111-111111111111',
            accountId: 'card',
            currencyCode: 'VND',
            amountMinor: '-150000',
          ),
        ],
      ),
    );
    expect(model.items, hasLength(1));
    auth.lock();
    await Future<void>.delayed(Duration.zero);
    expect(model.items, hasLength(1));

    await auth.forgetDevice();
    await Future<void>.delayed(Duration.zero);
    expect(auth.stage, AuthStage.signedOut);
    expect(model.items, isEmpty);
    expect(repository.items, isEmpty);
    model.dispose();
  });
}

DefaultSyncViewModel _model(
  _Repository repository,
  DefaultAuthViewModel auth,
  RecordingAnalytics analytics,
) {
  return DefaultSyncViewModel(DefaultSyncUseCases(repository), auth, analytics);
}

class _Repository implements SyncRepository {
  _Repository(this.items);

  List<SyncQueueItem> items;
  AuthFailure? failure;
  List<SyncItemResult>? results;
  final batches = <List<SyncQueueItem>>[];

  @override
  Future<List<SyncQueueItem>> read() async => items;

  @override
  Future<void> write(List<SyncQueueItem> value) async => items = value;

  @override
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  ) async {
    batches.add(batch);
    if (failure != null) return left(failure!);
    return right(
      results ??
          [
            for (final item in batch)
              SyncItemResult(
                opId: item.opId,
                status: 'applied',
                review: false,
                duplicateHint: false,
              ),
          ],
    );
  }
}

SyncQueueItem _item(
  String opId, {
  String clientId = '11111111-1111-4111-8111-111111111111',
  DateTime? createdAt,
}) {
  return SyncQueueItem(
    opId: opId,
    clientId: clientId,
    action: SyncAction.create,
    type: TransactionType.expense,
    occurredOn: '2026-01-15',
    notes: 'secret-note',
    legs: [
      SyncLeg(
        clientId: clientId,
        accountId: 'card',
        currencyCode: 'VND',
        amountMinor: '-150000',
      ),
    ],
    createdAt: createdAt ?? DateTime.utc(2026, 1, 15),
    retryCount: 0,
    status: SyncItemStatus.pending,
    review: false,
  );
}
