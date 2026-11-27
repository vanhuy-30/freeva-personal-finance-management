import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/store/store_launcher.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/pages/sync_page.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_item_row.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';

import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

void main() {
  late FixedSync model;

  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
    model = FixedSync([
      syncItem(
        'conflict',
        action: SyncAction.update,
        status: SyncItemStatus.conflict,
        reason: SyncReason.changedElsewhere,
        merchant: 'Phở Thìn',
        amount: -65000,
      ),
      syncItem(
        'failed',
        status: SyncItemStatus.failed,
        reason: SyncReason.unavailable,
        merchant: 'Taxi',
        amount: -120000,
      ),
      syncItem('wait', merchant: 'Highlands'),
    ]);
    getIt
      ..registerSingleton<SyncViewModel>(model)
      ..registerSingleton<TransactionViewModel>(StubTransactionViewModel());
  });

  tearDown(() => getIt.reset());

  Widget app({String locale = 'vi', double scale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: Locale(locale),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: const SyncPage(),
  );

  Future<void> show(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  testWidgets('lists what needs a look and what waits, with a reason each', (
    tester,
  ) async {
    model.link = SyncLink.offline;
    model.lastSyncedAt = DateTime.now().toUtc();
    await show(tester, app());
    expect(find.text('Chưa có mạng'), findsOneWidget);
    expect(find.textContaining('hôm nay'), findsOneWidget);
    expect(find.text('CẦN BẠN XEM · 2'), findsOneWidget);
    expect(find.text('ĐANG CHỜ GỬI · 1'), findsOneWidget);
    // Action tag + reason, read as one line.
    expect(find.bySemanticsLabel('Sửa · Đã đổi trên máy khác'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Thêm · Chưa gửi được · Thử lại sau'),
      findsOneWidget,
    );
    expect(
      find.text('Dữ liệu vẫn nằm trên máy này cho tới khi gửi xong.'),
      findsOneWidget,
    );
  });

  testWidgets('a held change can be tried again only when that can help', (
    tester,
  ) async {
    await show(tester, app());
    // Only the failed (not the conflicting) row offers it.
    final inRows = find.descendant(
      of: find.byType(SyncItemRow),
      matching: find.text('Thử lại'),
    );
    expect(inRows, findsOneWidget);
    await tester.tap(inRows);
    expect(model.retried, ['failed']);
  });

  testWidgets('discarding asks first and keeps the change on "Giữ lại"', (
    tester,
  ) async {
    await show(tester, app());
    await tester.tap(find.byTooltip('Bỏ thay đổi Highlands'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi này?'), findsOneWidget);
    expect(
      find.text('Khoản Highlands −55.000 sẽ không được lưu.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Giữ lại'));
    await tester.pumpAndSettle();
    expect(model.items.map((i) => i.opId), contains('wait'));
    await tester.tap(find.byTooltip('Bỏ thay đổi Highlands'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Bỏ')),
    );
    await tester.pumpAndSettle();
    expect(model.items.map((i) => i.opId), isNot(contains('wait')));
  });

  testWidgets('a change with no amount of its own borrows it from the list', (
    tester,
  ) async {
    final row = StubTransactionViewModel().rows.first;
    model.items = [
      syncItem(
        'del',
        action: SyncAction.delete,
        serverId: row.id,
        amount: null,
      ),
    ];
    await show(tester, app());
    expect(find.bySemanticsLabel(RegExp('^Xoá · ')), findsOneWidget);
    expect(find.textContaining('−'), findsWidgets);
  });

  testWidgets('sending shows progress without per-item counts', (tester) async {
    model.syncing = true;
    await show(tester, app());
    expect(find.text('Đang gửi 1 thay đổi'), findsOneWidget);
    expect(find.text('Có thể dùng app như bình thường'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('ĐANG GỬI'), findsOneWidget);
    expect(find.text('Thêm · −55.000'), findsOneWidget);
    expect(find.byTooltip('Bỏ thay đổi Highlands'), findsNothing);
  });

  testWidgets('needs an update: says so and keeps everything on the device', (
    tester,
  ) async {
    model.schemaMismatch = true;
    await show(tester, app());
    expect(find.text('Cần cập nhật Freeva'), findsOneWidget);
    expect(find.text('ĐANG GIỮ TRÊN MÁY · 3'), findsOneWidget);
    expect(find.text('Thử lại'), findsNothing);
  });

  group('Sửa', () {
    SyncItemRow rowOf(WidgetTester tester, int index) =>
        tester.widget<SyncItemRow>(find.byType(SyncItemRow).at(index));

    Finder inRow(int index, String text) => find.descendant(
      of: find.byType(SyncItemRow).at(index),
      matching: find.text(text),
    );

    setUp(() {
      model.items = [
        syncItem(
          'fix',
          status: SyncItemStatus.failed,
          reason: SyncReason.invalid,
          merchant: 'Taxi',
        ),
        syncItem(
          'gone',
          status: SyncItemStatus.failed,
          reason: SyncReason.transactionMissing,
          merchant: 'Bún',
        ),
        syncItem(
          'later',
          status: SyncItemStatus.failed,
          reason: SyncReason.unavailable,
          merchant: 'Cơm',
        ),
        syncItem(
          'del',
          status: SyncItemStatus.failed,
          reason: SyncReason.invalid,
          action: SyncAction.delete,
          serverId: 's1',
          amount: null,
          merchant: 'Chè',
        ),
      ];
    });

    testWidgets('only data the server refused offers it', (tester) async {
      await show(tester, app());
      expect(find.byType(SyncItemRow), findsNWidgets(4));
      expect(rowOf(tester, 0).onEdit, isNotNull);
      expect(inRow(0, 'Sửa'), findsOneWidget);
      // Missing target, a failure that is not about the data, and a delete.
      for (final i in [1, 2, 3]) {
        expect(rowOf(tester, i).onEdit, isNull, reason: 'row $i');
        expect(inRow(i, 'Sửa'), findsNothing, reason: 'row $i');
      }
      expect(inRow(2, 'Thử lại'), findsOneWidget);
      expect(inRow(0, 'Thử lại'), findsNothing);
    });

    testWidgets('is off while a send is running', (tester) async {
      model.syncing = true;
      await show(tester, app());
      for (var i = 0; i < 4; i++) {
        expect(rowOf(tester, i).onEdit, isNull);
      }
    });

    testWidgets('a conflict still offers "Xem", not "Sửa"', (tester) async {
      model.items = [
        syncItem(
          'c',
          status: SyncItemStatus.conflict,
          reason: SyncReason.changedElsewhere,
          action: SyncAction.update,
          serverId: 's',
        ),
      ];
      await show(tester, app());
      expect(rowOf(tester, 0).onEdit, isNull);
    });

    testWidgets('opens the edit form for that change', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SyncPage()),
          GoRoute(
            path: '/sync/edit/:opId',
            builder: (_, state) =>
                Scaffold(body: Text('edit ${state.pathParameters['opId']}')),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();
      await tester.tap(inRow(0, 'Sửa'));
      await tester.pumpAndSettle();
      expect(find.text('edit fix'), findsOneWidget);
    });

    testWidgets('keeps "Bỏ" within reach on a small screen at large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(scale: 1.3));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(inRow(0, 'Sửa'), findsOneWidget);
      expect(inRow(0, 'Bỏ'), findsOneWidget);
      // Rows without "Sửa" are unchanged: still only their own buttons.
      expect(inRow(2, 'Thử lại'), findsOneWidget);
      expect(inRow(2, 'Bỏ'), findsNothing);
    });
  });

  group('update button', () {
    late _FakeStore store;
    setUp(() {
      store = _FakeStore();
      getIt.registerSingleton<StoreLauncher>(store);
      model.schemaMismatch = true;
    });

    testWidgets('opens the store', (tester) async {
      await show(tester, app());
      expect(find.text('Cập nhật'), findsOneWidget);
      await tester.tap(find.text('Cập nhật'));
      await tester.pump();
      expect(store.opened, 1);
      expect(find.textContaining('Chưa mở được cửa hàng'), findsNothing);
    });

    testWidgets('says so when the store cannot be opened', (tester) async {
      store.opens = false;
      await show(tester, app());
      await tester.tap(find.text('Cập nhật'));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Chưa mở được cửa hàng'), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 7));
    });

    testWidgets('is hidden without a store page, the card stays', (
      tester,
    ) async {
      store.available = false;
      await show(tester, app());
      expect(find.text('Cần cập nhật Freeva'), findsOneWidget);
      expect(find.text('Cập nhật'), findsNothing);
    });

    testWidgets('is not shown when no update is needed', (tester) async {
      model.schemaMismatch = false;
      await show(tester, app());
      expect(find.text('Cập nhật'), findsNothing);
    });

    testWidgets('fits a small screen at large text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final locale in ['vi', 'en']) {
        await tester.pumpWidget(app(locale: locale, scale: 1.3));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: locale);
        expect(
          find.text(locale == 'vi' ? 'Cập nhật' : 'Update'),
          findsOneWidget,
        );
      }
    });
  });

  testWidgets('nothing queued and online reads as done', (tester) async {
    model.items = const [];
    await show(tester, app());
    expect(find.text('Đã đồng bộ hết'), findsOneWidget);
    expect(find.text('Chưa đồng bộ lần nào'), findsOneWidget);
    expect(
      find.text('Dữ liệu vẫn nằm trên máy này cho tới khi gửi xong.'),
      findsNothing,
    );
  });

  testWidgets('fits a small screen at large text in both languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final locale in ['vi', 'en']) {
      for (final flag in ['idle', 'offline', 'update', 'sending']) {
        model
          ..link = flag == 'offline' ? SyncLink.offline : SyncLink.ok
          ..schemaMismatch = flag == 'update'
          ..syncing = flag == 'sending';
        await tester.pumpWidget(app(locale: locale, scale: 1.3));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$locale $flag');
      }
    }
  });

  testWidgets('"Xem" appears only for a conflict that has a server copy', (
    tester,
  ) async {
    await show(tester, app());
    expect(find.text('Xem'), findsNothing);
    model.items = [
      model.items.first.copyWith(
        server: const SyncServerCopy(
          id: 'srv-1',
          version: 2,
          occurredOn: '2026-10-22',
          amountMinor: '-60000',
          currencyCode: 'VND',
        ),
      ),
      ...model.items.skip(1),
    ];
    model.notifyListeners();
    await tester.pump();
    expect(find.text('Xem'), findsOneWidget);
  });
}

class _FakeStore implements StoreLauncher {
  int opened = 0;
  bool opens = true;
  @override
  bool available = true;
  @override
  Future<bool> open() async {
    opened++;
    return opens;
  }
}
