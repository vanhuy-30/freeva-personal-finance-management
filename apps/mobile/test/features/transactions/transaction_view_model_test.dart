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
  late RecordingAnalytics analytics;

  setUp(() async {
    api = ScriptedApi();
    analytics = RecordingAnalytics();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    final walletCases = DefaultWalletUseCases(WalletRepositoryImpl(api));
    wallets = DefaultWalletViewModel(walletCases, auth);
    sync = DefaultSyncViewModel(
      DefaultSyncUseCases(MemorySyncRepository()),
      auth,
      analytics,
    );
    model = DefaultTransactionViewModel(
      DefaultTransactionUseCases(TransactionRepositoryImpl(api)),
      DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
      walletCases,
      wallets,
      ProfileUseCases(MemoryProfiles()),
      auth,
      analytics,
      sync,
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
    }
    expect(analytics.events.single['event'], 'transaction_created');
    expect(analytics.events.single['type'], 'expense');
    expect(analytics.events.single.containsKey('amountMinor'), isFalse);
    expect(api.calls.any((call) => call.path == 'categories/defaults'), isTrue);
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
}

TransactionDraft _draft(String clientId) => TransactionDraft(
  type: TransactionType.expense,
  occurredOn: '2026-01-15',
  accountId: 'card',
  magnitude: BigInt.from(150000),
  clientIds: [clientId],
  categoryId: 'food',
);
