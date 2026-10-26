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
    expect(find.text('1.250,00'), findsOneWidget);
    expect(find.text('USD · 1 ví'), findsOneWidget);
    expect(find.bySemanticsLabel('1.250,00 USD · 1 ví'), findsOneWidget);
    expect(find.text('Ví USD: chi 35,00 USD tháng này'), findsOneWidget);
  });

  testWidgets('B4 debt goal puts the credit cards above spending', (
    tester,
  ) async {
    await pump(tester, 'debt');
    expect(find.text('Thẻ tín dụng'), findsOneWidget);
    expect(find.text('Đến hạn 25/10'), findsOneWidget);
    expect(find.text('Đến hạn 12/11'), findsOneWidget);
    expect(
      find.textContaining('15.600.000', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Hạn mức 20.000.000'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Thẻ tín dụng')).dy,
      lessThan(tester.getTopLeft(find.text('Chi tháng 10').last).dy),
    );
  });

  testWidgets('without the debt goal the credit cards follow spending', (
    tester,
  ) async {
    final model = homeState('debt')..debtGoal = false;
    await tester.pumpWidget(await homeApp(model));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getTopLeft(find.text('Thẻ tín dụng')).dy,
      greaterThan(tester.getTopLeft(find.text('Chi tháng 10').last).dy),
    );
  });

  testWidgets('B5 new month: empty spending and last month review', (
    tester,
  ) async {
    await pump(tester, 'newMonth');
    expect(find.text('Chưa có khoản chi nào.'), findsOneWidget);
    expect(find.text('Ghi chi'), findsOneWidget);
    expect(find.text('Xem lại tháng 10'), findsOneWidget);
    expect(find.textContaining('01/11'), findsOneWidget);
    expect(find.text('Bắt đầu nào'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Chi tháng 11').last).dy,
      lessThan(tester.getTopLeft(find.text('Xem lại tháng 10')).dy),
    );
  });

  testWidgets('first run: greeting, compact balance, checklist, hint', (
    tester,
  ) async {
    await pump(tester, 'firstRun');
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Tổng số dư · 1 ví'), findsOneWidget);
    expect(find.text('Bắt đầu nào'), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('Ghi ngay'), findsOneWidget);
    expect(find.text('Khoá app bằng PIN'), findsOneWidget);
    expect(find.text('Giao dịch sẽ hiện ở đây'), findsOneWidget);
    expect(find.text('Ghi thu'), findsNothing);
    expect(find.byTooltip('Tìm giao dịch'), findsNothing);
    expect(find.byTooltip('Ẩn số dư'), findsNothing);
    expect(find.text('Thu tháng 10'), findsNothing);
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
    expect(find.text('Đang ngoại tuyến'), findsOneWidget);
    expect(find.text('Số liệu lúc 09:30. Vẫn ghi chi được.'), findsOneWidget);
    expect(find.text('Highlands'), findsOneWidget);
    expect(find.text('Chờ đồng bộ'), findsOneWidget);
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

  for (final state in [
    'ready',
    'multi',
    'debt',
    'newMonth',
    'loading',
    'offline',
    'error',
    'firstRun',
  ]) {
    testWidgets('$state fits 320 pt at 1.3× text', (tester) async {
      tester.view.physicalSize = const Size(320, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, state, scale: 1.3);
      expect(tester.takeException(), isNull);
    });
  }
}
