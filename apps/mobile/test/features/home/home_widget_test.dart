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
    await tester.pumpWidget(
      await homeApp(homeState(state), scale: scale, goals: homeGoals(state)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('PA 3 shows net worth, quick actions, tiles and recent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, 'ready');
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Tài sản ròng'), findsOneWidget);
    expect(find.textContaining('703.609.734'), findsOneWidget);
    expect(find.text('1,8% tháng này'), findsOneWidget);
    expect(find.text('966.009.734'), findsOneWidget);
    expect(find.text('262.400.000'), findsOneWidget);
    expect(find.text('Đầu tư chiếm 92%'), findsOneWidget);
    expect(find.text('Bằng 27% tài sản'), findsOneWidget);
    expect(find.text('Ghi thu'), findsOneWidget);
    expect(find.text('Tháng 11 còn'), findsOneWidget);
    expect(find.text('9.600.000'), findsOneWidget);
    expect(find.text('Đúng nhịp'), findsOneWidget);
    expect(find.text('Khoảng 480.000 mỗi ngày'), findsOneWidget);
    expect(find.text('Đã chi 5.400.000 / 15.000.000'), findsOneWidget);
    expect(find.text('31.030.000'), findsOneWidget);
    expect(find.text('3 khoản đến 30/11'), findsOneWidget);
    expect(find.text('Học phí còn 5 ngày'), findsOneWidget);
    expect(find.text('Thẻ chính · hạn 25/11'), findsOneWidget);
    expect(find.text('Mua nhà'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('+8,0%'), findsOneWidget);
    expect(find.text('Lãi 63.229.734'), findsOneWidget);
    expect(find.text('Phở Thìn'), findsOneWidget);
    expect(find.text('−65.000'), findsOneWidget);
    expect(
      find.bySemanticsLabel('trừ 65.000 đồng, Phở Thìn, Ăn uống · Tiền mặt'),
      findsOneWidget,
    );
    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Ghi thu'), greaterThan(top('Bằng 27% tài sản')));
    expect(top('Tháng 11 còn'), greaterThan(top('Ghi thu')));
    expect(top('Sắp phải trả'), greaterThan(top('Tháng 11 còn')));
    expect(top('Sắp phải trả'), top('Thẻ tín dụng'));
  });

  testWidgets('B2 hides balances only', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, 'hidden');
    expect(find.textContaining('703.609.734'), findsNothing);
    expect(find.text('966.009.734'), findsNothing);
    expect(find.text('262.400.000'), findsNothing);
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('số dư đã ẩn'), findsNWidgets(3));
    handle.dispose();
    expect(find.text('9.600.000'), findsOneWidget);
    expect(find.text('31.030.000'), findsOneWidget);
    expect(find.text('−65.000'), findsOneWidget);
  });

  testWidgets('B3 keeps other currencies apart', (tester) async {
    await pump(tester, 'multi');
    expect(find.text('Tài sản ròng'), findsOneWidget);
    expect(find.text('1.250,00'), findsOneWidget);
    expect(find.text('USD · 1 ví'), findsOneWidget);
    expect(find.bySemanticsLabel('1.250,00 USD · 1 ví'), findsOneWidget);
  });

  testWidgets('B4 the card tile shows the most used card', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, 'debt');
    expect(find.text('Thẻ tín dụng'), findsOneWidget);
    expect(find.text('Thẻ chính · hạn 25/10'), findsOneWidget);
    expect(find.text('17.400.000'), findsOneWidget);
    expect(find.textContaining('78%', findRichText: true), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Thẻ tín dụng')).dy,
      greaterThan(tester.getTopLeft(find.text('Tháng 10 còn')).dy),
    );
  });

  testWidgets('B5 new month: no budget yet and last month review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, 'newMonth');
    expect(find.text('Chi tháng 11'), findsOneWidget);
    expect(find.text('Đặt ngân sách'), findsOneWidget);
    expect(find.text('Xem lại tháng 10'), findsOneWidget);
    expect(find.textContaining('01/11'), findsOneWidget);
    expect(find.text('Bắt đầu nào'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Chi tháng 11')).dy,
      lessThan(tester.getTopLeft(find.text('Xem lại tháng 10')).dy),
    );
  });

  testWidgets('first run: greeting, compact balance, checklist, hint', (
    tester,
  ) async {
    await pump(tester, 'firstRun');
    expect(find.text('Chào Minh'), findsOneWidget);
    expect(find.text('Tổng số dư'), findsOneWidget);
    expect(find.text('Bắt đầu nào'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
    expect(find.text('Thêm ví đầu tiên'), findsOneWidget);
    expect(find.text('Thêm ví'), findsOneWidget);
    expect(find.text('Ghi ngay'), findsNothing);
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
    expect(find.textContaining('48.250.000'), findsWidgets);
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
    expect(find.textContaining('703.609.734'), findsNothing);
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
