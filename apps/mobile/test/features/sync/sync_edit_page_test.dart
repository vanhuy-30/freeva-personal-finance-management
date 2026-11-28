import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/pages/sync_edit_page.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';

import '../../support/server_config_fixture.dart';
import '../auth/fakes.dart';
import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

void main() {
  late DefaultAuthViewModel auth;
  late FixedSync sync;
  late StubTransactionViewModel transactions;

  SyncQueueItem failed({
    String opId = 'fix',
    SyncItemStatus status = SyncItemStatus.failed,
    SyncReason? reason = SyncReason.invalid,
  }) => syncItem(
    opId,
    status: status,
    reason: reason,
    merchant: 'Phở Thìn',
    categoryId: 'food',
  );

  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
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
          ..ready = true
          ..stage = AuthStage.unlocked;
    sync = FixedSync([failed()]);
    transactions = StubTransactionViewModel();
    getIt
      ..registerSingleton<AuthViewModel>(auth)
      ..registerSingleton<SyncViewModel>(sync)
      ..registerSingleton<TransactionViewModel>(transactions);
  });

  tearDown(() async {
    auth.dispose();
    await getIt.reset();
    registerTestServerConfig();
  });

  Future<GoRouter> open(
    WidgetTester tester, {
    String opId = 'fix',
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(390, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/sync/edit/$opId',
      routes: [
        GoRoute(
          path: '/sync',
          builder: (_, __) => const Scaffold(body: Text('danh sách đồng bộ')),
          routes: [
            GoRoute(
              path: 'edit/:opId',
              builder: (_, state) =>
                  SyncEditPage(opId: state.pathParameters['opId']!),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        routerConfig: router,
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return router;
  }

  testWidgets('opens the form filled with the failed change', (tester) async {
    await open(tester);
    expect(find.text('Phở Thìn'), findsWidgets);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    // The kind is fixed: a queued change keeps its type and ids.
    expect(find.text('Sửa khoản chi'), findsOneWidget);
  });

  testWidgets('saving hands the change back to the queue and closes the form', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(transactions.savedQueued, hasLength(1));
    final (draft, item) = transactions.savedQueued.single;
    expect(item.opId, 'fix');
    expect(draft.clientIds, [item.legs.single.clientId]);
    expect(draft.magnitude, BigInt.from(55000));
    expect(draft.merchant, 'Phở Thìn');
    expect(draft.categoryId, 'food');
    expect(draft.accountId, 'cash');
    // Nothing went to the server-first path.
    expect(transactions.saved, isEmpty);
  });

  testWidgets('a refused save keeps the form open', (tester) async {
    transactions.queuedSaves = false;
    await open(tester);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(transactions.savedQueued, hasLength(1));
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(find.text('danh sách đồng bộ'), findsNothing);
  });

  testWidgets('the form keeps working after the queue drops the item', (
    tester,
  ) async {
    await open(tester);
    // Sent and removed from the list while the form is still open.
    sync.items = const [];
    sync.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsOneWidget);
    expect(find.text('danh sách đồng bộ'), findsNothing);
  });

  testWidgets('an unknown change goes back to the list', (tester) async {
    await open(tester, opId: 'nope');
    expect(find.text('danh sách đồng bộ'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsNothing);
  });

  testWidgets('a change that cannot be fixed by editing goes back too', (
    tester,
  ) async {
    sync.items = [failed(reason: SyncReason.unavailable)];
    await open(tester);
    expect(find.text('danh sách đồng bộ'), findsOneWidget);
  });

  testWidgets('waits for wallets and categories, then shows the form', (
    tester,
  ) async {
    transactions.composerReady = false;
    await open(tester, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsNothing);
    transactions
      ..composerReady = true
      ..notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });
}
