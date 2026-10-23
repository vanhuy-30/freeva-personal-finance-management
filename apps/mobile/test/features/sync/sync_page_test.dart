import 'package:flutter/material.dart';
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
    expect(find.textContaining('Lần cuối hôm nay'), findsOneWidget);
    expect(find.text('CẦN BẠN XEM · 2'), findsOneWidget);
    expect(find.text('ĐANG CHỜ GỬI · 1'), findsOneWidget);
    expect(find.text('Sửa · Đã đổi trên máy khác'), findsOneWidget);
    expect(find.text('Thêm · Chưa gửi được · Thử lại sau'), findsOneWidget);
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
    expect(find.textContaining('Xoá ·'), findsOneWidget);
    expect(find.textContaining('−'), findsWidgets);
  });

  testWidgets('sending shows progress without per-item counts', (tester) async {
    model.syncing = true;
    await show(tester, app());
    expect(find.text('Đang gửi 1 thay đổi'), findsOneWidget);
    expect(find.text('Có thể dùng app như bình thường'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
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

  testWidgets('nothing queued and online reads as done', (tester) async {
    model.items = const [];
    await show(tester, app());
    expect(find.text('Đã đồng bộ hết'), findsOneWidget);
    expect(find.text('Chưa đồng bộ lần nào'), findsOneWidget);
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
}
