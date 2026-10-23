import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/sync/domain/sync_use_cases.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/tags/data/tag_repository_impl.dart';
import 'package:mobile/features/tags/domain/tag_use_cases.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_results_view_model.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../auth/fakes.dart';
import '../profile/fakes.dart';
import 'transaction_fakes.dart';
import 'transaction_view_model_test.dart'
    show MemorySyncRepository, RecordingAnalytics;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late ScriptedApi api;
  late DefaultTransactionViewModel model;

  setUp(() async {
    api = ScriptedApi();
    final auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    final walletCases = DefaultWalletUseCases(WalletRepositoryImpl(api));
    final analytics = RecordingAnalytics();
    model = DefaultTransactionViewModel(
      DefaultTransactionUseCases(TransactionRepositoryImpl(api)),
      DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
      DefaultTagUseCases(TagRepositoryImpl(api)),
      walletCases,
      DefaultWalletViewModel(walletCases, auth),
      ProfileUseCases(MemoryProfiles()),
      auth,
      analytics,
      DefaultSyncViewModel(
        DefaultSyncUseCases(MemorySyncRepository()),
        auth,
        analytics,
      ),
    );
    await model.load();
  });

  Uri lastList() => Uri.parse(
    'http://local/${api.calls.lastWhere((c) => c.path.startsWith('transactions?')).path}',
  );

  test('the list defaults to this month and keeps the summary', () async {
    api.summary = {'count': 1, 'totals': []};
    await model.setFilter(TransactionFilter.list);
    expect(lastList().queryParameters['from'], isNotNull);
    expect(model.summary.count, 1);
  });

  test('a newer filter wins over a page still loading', () async {
    api.listPending = Completer<void>();
    final slow = model.setFilter(
      const TransactionFilter(type: TransactionType.income),
    );
    final fast = model.setFilter(
      const TransactionFilter(type: TransactionType.expense),
    );
    api.listPending!.complete();
    await Future.wait([slow, fast]);
    expect(model.filter.type, TransactionType.expense);
    expect(model.listLoading, isFalse);
  });

  test('countFor asks for one row and reads the bundle count', () async {
    api.summary = {'count': 24, 'totals': []};
    expect(
      await model.countFor(const TransactionFilter(accountIds: {'cash'})),
      24,
    );
    expect(lastList().queryParameters['pageSize'], '1');
    expect(lastList().queryParametersAll['accountId'], ['cash']);
  });

  test('deletedCount reads deleted transactions of all time', () async {
    api.summary = {'count': 4, 'totals': []};
    expect(await model.deletedCount(), 4);
    expect(lastList().queryParameters['status'], 'deleted');
    expect(lastList().queryParameters['from'], isNull);
  });

  test('undoRemove re-reads the deleted copy before restoring', () async {
    final row = model.rows.single;
    expect(await model.remove(row), isTrue);
    api.deletedRead = true;
    final undone = await model.undoRemove(row);
    expect(model.failure?.code, isNull);
    expect(undone, isTrue);
    final patch = api.calls.lastWhere((c) => c.method == 'PATCH');
    expect(patch.body!['deleted'], isFalse);
  });

  test('search waits 300 ms after typing and ignores empty text', () {
    fakeAsync((async) {
      final results = DefaultTransactionResultsViewModel(
        DefaultTransactionUseCases(TransactionRepositoryImpl(api)),
        model,
      );
      final before = api.calls.length;
      results.setSearch('p');
      results.setSearch('ph');
      results.setSearch('phở');
      async.elapse(const Duration(milliseconds: 299));
      expect(api.calls.length, before);
      async.elapse(const Duration(milliseconds: 2));
      async.flushMicrotasks();
      expect(api.calls.length, before + 1);
      expect(lastList().queryParameters['search'], 'phở');
      expect(lastList().queryParameters['from'], isNull);
      results.setSearch('  ');
      async.elapse(const Duration(milliseconds: 301));
      async.flushMicrotasks();
      expect(api.calls.length, before + 1);
      expect(results.rows, isEmpty);
      results.dispose();
    });
  });
}
