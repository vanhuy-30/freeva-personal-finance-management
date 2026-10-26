import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/home/presentation/widgets/overview_states.dart';

import 'home_test_app.dart';

void main() {
  tearDown(() => getIt.reset());

  Future<void> pump(
    WidgetTester tester,
    String state, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(await homeApp(homeState(state), scale: scale));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('B1 shows greeting, balance, spending and recent', (
    tester,
  ) async {
    await pump(tester, 'ready');
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Tổng số dư · 4 ví'), findsOneWidget);
    expect(find.textContaining('48.250.000'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('38%'), findsOneWidget);
    expect(find.text('Khác'), findsOneWidget);
    expect(find.text('Phở Thìn'), findsOneWidget);
    expect(find.text('−65.000'), findsOneWidget);
    expect(find.text('+18.500.000'), findsWidgets);
    expect(
      find.bySemanticsLabel('trừ 65.000 đồng, Phở Thìn, Ăn uống · Tiền mặt'),
      findsOneWidget,
    );
  });

  testWidgets('B2 hides balances only', (tester) async {
    await pump(tester, 'hidden');
    expect(find.textContaining('48.250.000'), findsNothing);
    expect(find.textContaining('••••••', findRichText: true), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('số dư đã ẩn'), findsOneWidget);
    handle.dispose();
    expect(find.text('−65.000'), findsOneWidget);
    expect(find.text('+18.500.000'), findsWidgets);
    expect(find.text('Ăn uống'), findsOneWidget);
  });

  testWidgets('B3 keeps other currencies apart', (tester) async {
    await pump(tester, 'multi');
    expect(find.text('Tổng số dư · 4 ví VND'), findsOneWidget);
    expect(find.text('1.250,00 USD · 1 ví'), findsOneWidget);
    expect(find.text('Ví USD: chi 35,00 USD tháng này'), findsOneWidget);
  });

  testWidgets('B4 shows the credit card block', (tester) async {
    await pump(tester, 'debt');
    expect(find.text('Thẻ tín dụng'), findsOneWidget);
    expect(find.text('Đến hạn 25/10'), findsOneWidget);
    expect(find.text('Đã dùng 6.200.000 / Hạn mức 20.000.000'), findsOneWidget);
  });

  testWidgets('B5 new month: empty spending and last month review', (
    tester,
  ) async {
    await pump(tester, 'newMonth');
    expect(find.text('Chưa có khoản chi nào.'), findsOneWidget);
    expect(find.text('Ghi chi'), findsOneWidget);
    expect(find.text('Xem lại tháng 10'), findsOneWidget);
    expect(find.text('Giao dịch sẽ hiện ở đây'), findsOneWidget);
  });

  testWidgets('B6 loading keeps greeting and quick actions, no fake zero', (
    tester,
  ) async {
    await pump(tester, 'loading');
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Ghi thu'), findsOneWidget);
    expect(find.byType(BalanceSkeleton), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('B7 offline keeps data with the time', (tester) async {
    await pump(tester, 'offline');
    expect(find.text('Đang ngoại tuyến · Số liệu lúc 09:30'), findsOneWidget);
    expect(find.textContaining('48.250.000'), findsOneWidget);
  });

  testWidgets('B8 error card retries', (tester) async {
    final model = homeState('error');
    await tester.pumpWidget(await homeApp(model));
    await tester.pump();
    expect(find.text('Chưa tải được số dư'), findsOneWidget);
    expect(find.text('Dữ liệu của bạn vẫn an toàn.'), findsOneWidget);
    final before = model.loads;
    await tester.tap(find.text('Thử lại'));
    expect(model.loads, before + 1);
    expect(find.text('Ghi thu'), findsOneWidget);
  });

  testWidgets('the eye toggles hiding', (tester) async {
    await pump(tester, 'ready');
    await tester.tap(find.byTooltip('Ẩn số dư'));
    await tester.pump();
    expect(find.textContaining('48.250.000'), findsNothing);
  });

  for (final state in ['ready', 'multi', 'debt', 'newMonth', 'error']) {
    testWidgets('$state fits 320 pt at 1.3× text', (tester) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, state, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }
}
