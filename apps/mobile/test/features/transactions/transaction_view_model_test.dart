import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/analytics_service.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/tags/data/tag_repository_impl.dart';
import 'package:mobile/features/tags/domain/tag_use_cases.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/sync/domain/sync_repository.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/domain/sync_use_cases.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../auth/fakes.dart';
import '../profile/fakes.dart';
import 'transaction_fakes.dart';

import 'package:mobile/features/fx_rates/domain/fx_rate_use_cases.dart';

import '../fx_rates/fakes.dart';
import '../../support/server_config_fixture.dart';

class RecordingAnalytics implements AnalyticsService {
  final events = <Map<String, Object>>[];
  @override
  void track(AnalyticsEvent event) => events.add(event.toPayload());
}

class MemorySyncRepository implements SyncRepository {
  List<SyncQueueItem> items = const [];

  @override
  Future<List<SyncQueueItem>> read() async => items;

  @override
  Future<void> write(List<SyncQueueItem> value) async => items = value;

  DateTime? stamp;
  @override
  Future<DateTime?> lastSyncedAt() async => stamp;
  @override
  Future<void> markSynced(DateTime at) async => stamp = at;
  @override
  Future<void> clear() async {
    items = const [];
    stamp = null;
  }

  @override
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  ) async => right(const []);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late ScriptedApi api;
  late DefaultAuthViewModel auth;
  late DefaultWalletViewModel wallets;
  late DefaultTransactionViewModel model;
  late DefaultSyncViewModel sync;
  late MemorySyncRepository syncRepo;
  late RecordingAnalytics analytics;

  setUp(() async {
    api = ScriptedApi();
    analytics = RecordingAnalytics();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(
                FakeApi(),
                MemoryVault(),
                FakeBiometrics(),
                testServerConfigModel(),
              ),
              testServerConfigModel(),
            ),
          )
          ..stage = AuthStage.unlocked
          ..hasPin = true
          ..ready = true;
    final walletCases = DefaultWalletUseCases(
      WalletRepositoryImpl(api),
      testServerConfigModel(),
    );
    wallets = DefaultWalletViewModel(walletCases, auth);
    sync = DefaultSyncViewModel(
      DefaultSyncUseCases(syncRepo = MemorySyncRepository()),
      auth,
      analytics,
    );
    model = DefaultTransactionViewModel(
      DefaultTransactionUseCases(
        TransactionRepositoryImpl(api),
        testServerConfigModel(),
      ),
      DefaultCategoryUseCases(
        CategoryRepositoryImpl(api),
        testServerConfigModel(),
      ),
      DefaultTagUseCases(TagRepositoryImpl(api), testServerConfigModel()),
      walletCases,
      wallets,
      ProfileUseCases(MemoryProfiles(), testServerConfigModel()),
      auth,
      analytics,
      sync,
      FxRateUseCases(MemoryFxRates(), FxWallets()),
      testServerConfigModel(),
    );
    await model.load();
  });

  tearDown(() {
    model.dispose();
    sync.dispose();
    wallets.dispose();
    auth.dispose();
  });

  test('defaults to the recent active wallet and pages legs', () async {
    expect(model.preferredAccountId(), 'card');
    expect(model.preferredCategoryId(), 'food');
    expect(model.timeZone, 'Asia/Ho_Chi_Minh');
    api.paginate = true;
    await model.load();
    expect(model.rows, hasLength(1));
    await model.loadMore();
    expect(model.rows, hasLength(2));
    expect(model.hasMore, isFalse);
  });

  test('create sends a negative amount and stable idempotency key', () async {
    final draft = _draft(model.newClientId());
    api.failWrite = 1;
    expect(await model.save(draft), isTrue);
    expect(sync.items, hasLength(1));
    expect(sync.items.single.legs.single.amountMinor, '-150000');
    expect(await model.save(draft), isTrue);
    expect(sync.items, isEmpty);
    final posts = api.calls.where(
      (call) => call.method == 'POST' && call.path == 'transactions',
    );
    expect(posts, hasLength(2));
    for (final call in posts) {
      expect(call.headers?['Idempotency-Key'], draft.clientIds.single);
      expect(call.body!['legs'][0]['amountMinor'], '-150000');
      expect(call.body!['type'], 'expense');
      expect(call.body!['merchant'], isNull);
      expect(call.body!['tagIds'], isEmpty);
    }
    expect(analytics.events.single['event'], 'transaction_created');
    expect(analytics.events.single['type'], 'expense');
    expect(analytics.events.single.containsKey('amountMinor'), isFalse);
    expect(api.calls.any((call) => call.path == 'categories/defaults'), isTrue);
    expect(model.tags.single.name, 'Work');
  });

  test('create attaches merchant and a newly created tag', () async {
    final tag = await model.createTag(
      'Family',
      clientId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    );
    expect(tag?.name, 'Family');
    final draft = TransactionDraft(
      type: TransactionType.expense,
      occurredOn: '2026-01-15',
      accountId: 'card',
      magnitude: BigInt.from(150000),
      clientIds: [model.newClientId()],
      categoryId: 'food',
      merchant: 'WinMart',
      tagIds: [tag!.id, 'work'],
    );
    expect(await model.save(draft), isTrue);
    final post = api.calls.lastWhere(
      (call) => call.method == 'POST' && call.path == 'transactions',
    );
    expect(post.body!['merchant'], 'WinMart');
    expect(post.body!['tagIds'], [tag.id, 'work']);
  });

  test(
    'conflict requires reload and a late response is dropped after lock',
    () async {
      final draft = _draft(model.newClientId());
      api.conflict = true;
      expect(await model.save(draft), isFalse);
      expect(model.needsReload, isTrue);
      expect(await model.save(draft), isFalse);
      expect(api.writes, 1);

      api.conflict = false;
      model.needsReload = false;
      api.pending = Completer<void>();
      final pending = model.save(_draft(model.newClientId()));
      await Future<void>.delayed(Duration.zero);
      auth.lock();
      api.pending!.complete();
      expect(await pending, isFalse);
      expect(model.wallets, isEmpty);
      expect(model.rows, isEmpty);
      expect(analytics.events, hasLength(0));
    },
  );

  group('saveQueued (Đồng bộ → Sửa)', () {
    Future<void> markFailed(SyncReason reason) async {
      syncRepo.items = [
        syncRepo.items.single.copyWith(
          status: SyncItemStatus.failed,
          reason: reason,
          retryCount: 3,
        ),
      ];
      await sync.flush();
      expect(sync.items.single.status, SyncItemStatus.failed);
    }

    TransactionDraft edited(SyncQueueItem item, {int amount = 99000}) =>
        TransactionDraft(
          type: TransactionType.expense,
          occurredOn: '2026-01-16',
          accountId: 'card',
          magnitude: BigInt.from(amount),
          clientIds: [for (final leg in item.legs) leg.clientId],
          categoryId: 'food',
          merchant: 'Grab',
        );

    test(
      'a failed create goes back in line in place, same ids, no server call',
      () async {
        api.failWrite = 1;
        expect(await model.save(_draft(model.newClientId())), isTrue);
        await markFailed(SyncReason.invalid);
        final item = sync.items.single;
        final writes = api.writes;
        expect(await model.saveQueued(edited(item), item), isTrue);
        // It is sent right away in the background; let that finish.
        await pumpEventQueue();
        expect(api.writes, writes);
        final next = sync.items.single;
        expect(next.opId, item.opId);
        expect(next.createdAt, item.createdAt);
        expect(next.clientId, item.clientId);
        expect(next.legs.single.clientId, item.legs.single.clientId);
        expect(next.action, SyncAction.create);
        expect(next.version, isNull);
        expect(next.status, SyncItemStatus.pending);
        expect(next.reason, isNull);
        expect(next.retryCount, 0);
        expect(next.legs.single.amountMinor, '-99000');
        expect(next.merchant, 'Grab');
        expect(next.occurredOn, '2026-01-16');
        expect(model.lastSaved, isNull);
        // The first save counted the creation; fixing it counts nothing more.
        expect(analytics.events, hasLength(1));
      },
    );

    test(
      'a failed update keeps its server id and the version it was queued with',
      () async {
        const clientId = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
        await sync.enqueue(
          const SyncMutation(
            action: SyncAction.update,
            clientId: clientId,
            serverId: 'tx-1',
            version: 3,
            type: TransactionType.expense,
            occurredOn: '2026-01-15',
            categoryId: 'food',
            legs: [
              SyncLeg(
                clientId: clientId,
                accountId: 'card',
                currencyCode: 'VND',
                amountMinor: '-150000',
              ),
            ],
          ),
        );
        await markFailed(SyncReason.categoryKind);
        final item = sync.items.single;
        expect(await model.saveQueued(edited(item), item), isTrue);
        // It is sent right away in the background; let that finish.
        await pumpEventQueue();
        final next = sync.items.single;
        expect(next.opId, item.opId);
        expect(next.action, SyncAction.update);
        expect(next.serverId, 'tx-1');
        expect(next.version, 3);
        expect(next.status, SyncItemStatus.pending);
        expect(next.legs.single.amountMinor, '-99000');
      },
    );

    test(
      'a draft the rules refuse leaves the item exactly as it was',
      () async {
        api.failWrite = 1;
        expect(await model.save(_draft(model.newClientId())), isTrue);
        await markFailed(SyncReason.walletMissing);
        final item = sync.items.single;
        expect(await model.saveQueued(edited(item, amount: 0), item), isFalse);
        expect(model.failure?.code, AuthError.invalidInput);
        final same = sync.items.single;
        expect(same.status, SyncItemStatus.failed);
        expect(same.reason, SyncReason.walletMissing);
        expect(same.retryCount, 3);
        expect(same.legs.single.amountMinor, item.legs.single.amountMinor);
      },
    );

    test('a wallet that is gone cannot be chosen again', () async {
      api.failWrite = 1;
      expect(await model.save(_draft(model.newClientId())), isTrue);
      await markFailed(SyncReason.walletMissing);
      final item = sync.items.single;
      final gone = TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-16',
        accountId: 'deleted-wallet',
        magnitude: BigInt.from(1000),
        clientIds: [item.legs.single.clientId],
        categoryId: 'food',
      );
      expect(await model.saveQueued(gone, item), isFalse);
      expect(sync.items.single.status, SyncItemStatus.failed);
    });
  });

  test(
    'composer is ready before the list finishes and save still works',
    () async {
      model.dispose();
      sync.dispose();
      wallets.dispose();
      api = ScriptedApi()..listPending = Completer<void>();
      final walletCases = DefaultWalletUseCases(
        WalletRepositoryImpl(api),
        testServerConfigModel(),
      );
      wallets = DefaultWalletViewModel(walletCases, auth);
      sync = DefaultSyncViewModel(
        DefaultSyncUseCases(MemorySyncRepository()),
        auth,
        analytics,
      );
      model = DefaultTransactionViewModel(
        DefaultTransactionUseCases(
          TransactionRepositoryImpl(api),
          testServerConfigModel(),
        ),
        DefaultCategoryUseCases(
          CategoryRepositoryImpl(api),
          testServerConfigModel(),
        ),
        DefaultTagUseCases(TagRepositoryImpl(api), testServerConfigModel()),
        walletCases,
        wallets,
        ProfileUseCases(MemoryProfiles(), testServerConfigModel()),
        auth,
        analytics,
        sync,
        FxRateUseCases(MemoryFxRates(), FxWallets()),
        testServerConfigModel(),
      );
      final loading = model.load();
      await Future<void>.delayed(Duration.zero);
      for (var i = 0; i < 20 && !model.composerReady; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(model.composerReady, isTrue);
      expect(model.canWrite, isTrue);
      expect(model.preferredCategoryId(), 'food');
      expect(model.preferredAccountId(), 'cash');
      expect(model.rows, isEmpty);
      final saving = model.save(_draft(model.newClientId()));
      api.listPending!.complete();
      expect(await saving, isTrue);
      await loading;
      expect(model.preferredAccountId(), 'card');
      expect(analytics.events.single['event'], 'transaction_created');
    },
  );
}

TransactionDraft _draft(String clientId) => TransactionDraft(
  type: TransactionType.expense,
  occurredOn: '2026-01-15',
  accountId: 'card',
  magnitude: BigInt.from(150000),
  clientIds: [clientId],
  categoryId: 'food',
);
