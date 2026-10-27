import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/pages/sync_page.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_mark_chip.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_status_banner.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_day_list.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

// macOS only. Update: flutter test --update-goldens test/features/sync/h1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  SyncQueueItem highlands() =>
      syncItem('h', merchant: 'Highlands', categoryId: 'coffee');
  SyncQueueItem grab() => syncItem(
    'g',
    action: SyncAction.update,
    merchant: 'Grab',
    amount: -48000,
    categoryId: 'car',
    createdAt: DateTime(2026, 10, 22, 9, 30),
  );
  SyncQueueItem coffee() => syncItem(
    'd',
    action: SyncAction.delete,
    merchant: 'Cà phê',
    amount: -39000,
    categoryId: 'coffee',
    createdAt: DateTime(2026, 10, 22, 8, 50),
  );
  List<SyncQueueItem> waitingOnly() => [highlands(), grab(), coffee()];

  FixedSync mixed() => FixedSync([
    syncItem(
      'conflict',
      action: SyncAction.update,
      status: SyncItemStatus.conflict,
      reason: SyncReason.changedElsewhere,
      merchant: 'Phở Thìn',
      amount: -65000,
      categoryId: 'food',
      serverId: 'srv-1',
    ).copyWith(
      server: const SyncServerCopy(
        id: 'srv-1',
        version: 2,
        occurredOn: '2026-10-22',
        amountMinor: '-60000',
        currencyCode: 'VND',
      ),
    ),
    syncItem(
      'invalid',
      status: SyncItemStatus.failed,
      reason: SyncReason.invalid,
      merchant: 'Taxi',
      amount: -120000,
      categoryId: 'car',
    ),
    ...waitingOnly(),
  ]);

  Future<void> shot(
    WidgetTester t,
    String name,
    FixedSync model, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Widget? home,
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await getIt.reset();
    getIt
      ..registerSingleton<SyncViewModel>(model)
      ..registerSingleton<TransactionViewModel>(
        StubTransactionViewModel()..categories = syncCategories,
      );
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('vi'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: home ?? const SyncPage(),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/h1_$name.png'),
    );
  }

  testWidgets('center', skip: !Platform.isMacOS, (t) async {
    final model = mixed()
      ..link = SyncLink.offline
      ..lastSyncedAt = DateTime(2026, 10, 22, 9, 30);
    await shot(t, 'center', model, size: const Size(390, 1000));
  });
  testWidgets('center dark compact', skip: !Platform.isMacOS, (t) async {
    final model = mixed()..link = SyncLink.unavailable;
    await shot(
      t,
      'center_compact',
      model,
      dark: true,
      scale: 1.3,
      size: const Size(320, 1700),
    );
  });
  testWidgets('sending', skip: !Platform.isMacOS, (t) async {
    final model = FixedSync(waitingOnly())..syncing = true;
    await shot(t, 'sending', model, size: const Size(390, 1000));
  });
  testWidgets('done', skip: !Platform.isMacOS, (t) async {
    final model = FixedSync(const [])
      ..lastSyncedAt = DateTime(2026, 10, 22, 9, 42);
    await shot(t, 'done', model, size: const Size(390, 500));
  });
  testWidgets('update needed', skip: !Platform.isMacOS, (t) async {
    final model = FixedSync(waitingOnly())..schemaMismatch = true;
    await shot(t, 'update', model, size: const Size(390, 900));
  });
  testWidgets('discard popup', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'discard',
      mixed(),
      size: const Size(390, 1000),
      then: () async {
        await t.tap(find.byTooltip('Bỏ thay đổi Highlands'));
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('list banner and marks', skip: !Platform.isMacOS, (t) async {
    final stub = StubTransactionViewModel();
    final rows = stub.rows.take(3).toList();
    final model = mixed();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SyncStatusBanner(),
                  TransactionDayList(
                    rows: rows,
                    naming: TransactionNaming(
                      S.of(context),
                      categories: stub.categories,
                      wallets: stub.wallets,
                      tags: stub.tags,
                    ),
                    digitsOf: (_) => 0,
                    mainCurrency: 'VND',
                    today: rows.first.occurredOn,
                    onOpen: (_) {},
                    markFor: (row) => row.id == rows[0].id
                        ? SyncMark.review
                        : row.id == rows[1].id
                        ? SyncMark.waiting
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await shot(
      t,
      'list',
      model,
      size: const Size(390, 700),
      home: Router(
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
        backButtonDispatcher: RootBackButtonDispatcher(),
      ),
    );
  });
}
