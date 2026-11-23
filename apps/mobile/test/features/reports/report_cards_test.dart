import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/insights/domain/insight.dart';
import 'package:mobile/features/reports/domain/category_detail.dart';
import 'package:mobile/features/reports/presentation/pages/report_breakdown_page.dart';
import 'package:mobile/features/reports/presentation/pages/report_page.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';

import '../insights/insights_fakes.dart';
import 'f1_stub.dart';

void _tall(WidgetTester t, {Size size = const Size(390, 2600)}) {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// The report page at 21/10/2026 with [cases] and optional insights.
Future<void> _open(
  WidgetTester t, {
  StubReportCases? cases,
  StubInsightsViewModel? insights,
  double scale = 1,
  Size size = const Size(390, 2600),
}) async {
  _tall(t, size: size);
  await t.pumpWidget(
    await f1App(
      const ReportPage(),
      cases: cases,
      insights: insights,
      scale: scale,
    ),
  );
  await t.pumpAndSettle();
}

const _october = InsightPeriod(
  from: '2026-10-01',
  to: '2026-10-31',
  today: '2026-10-21',
);

void main() {
  tearDown(() => getIt.reset());

  group('totals card', () {
    testWidgets('says Tổng thu nhập and Tổng chi tiêu, without a minus', (
      t,
    ) async {
      await _open(t);
      expect(find.text('Tổng thu nhập'), findsOneWidget);
      expect(find.text('Tổng chi tiêu'), findsOneWidget);
      expect(find.text('18.500.000'), findsOneWidget);
      expect(find.text('9.320.000'), findsOneWidget);
      expect(find.textContaining('−9.320.000'), findsNothing);
      expect(find.text('Tiết kiệm (thu − chi)'), findsOneWidget);
      expect(find.text('9.180.000'), findsOneWidget);
      expect(find.text('Tổng số dư ví'), findsOneWidget);
      expect(find.text('48.250.000'), findsOneWidget);
      expect(find.text('Chi trung bình/ngày'), findsOneWidget);
      expect(find.text('443.810'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('compares each figure with the month before', (t) async {
      await _open(t);
      // September: 17,0m in, 9,9m out, 39,07m in the wallets.
      expect(find.text('▲ 8,8%'), findsOneWidget); // income
      expect(find.text('▼ 5,9%'), findsOneWidget); // spending went down
      expect(find.text('▲ 29,3%'), findsOneWidget); // saving
      expect(find.text('▲ 23,5%'), findsOneWidget); // wallets
      expect(find.text('▲ 34,5%'), findsOneWidget); // average per day
      expect(find.text('▲ 7,9 điểm'), findsOneWidget); // savings rate
      expect(find.text('49,6%'), findsOneWidget); // the ring
      expect(find.text('so tháng trước'), findsNWidgets(5));
    });

    testWidgets('a custom range shows the figures and no comparison', (
      t,
    ) async {
      await _open(t);
      final model = getIt<ReportViewModel>();
      await model.applyRange('2026-10-06', '2026-10-19');
      await t.pumpAndSettle();
      expect(find.text('18.500.000'), findsOneWidget);
      expect(find.text('9.180.000'), findsOneWidget);
      expect(
        find.text('49,6%'),
        findsOneWidget,
      ); // the ring is not a comparison
      for (final change in [
        '▲ 8,8%',
        '▼ 5,9%',
        '▲ 29,3%',
        '▲ 23,5%',
        '▲ 34,5%',
      ]) {
        expect(find.text(change), findsNothing, reason: change);
      }
      expect(find.textContaining('so tháng trước'), findsNothing);
      expect(find.textContaining('điểm'), findsNothing);
      // The budget is the month's.
      expect(find.text('Đặt ngân sách tháng'), findsNothing);
      // The previous period was not even asked for.
    });
  });

  group('cash flow card', () {
    testWidgets('draws the running total and names the extremes', (t) async {
      await _open(t);
      expect(find.text('Dòng tiền trong tháng'), findsOneWidget);
      expect(find.text('Thu − chi, cộng dồn'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Dòng tiền ròng cộng dồn')),
        findsOneWidget,
      );
      expect(find.text('Thu lớn nhất · 05/10'), findsOneWidget);
      expect(find.text('+18.500.000'), findsOneWidget);
      expect(find.text('Chi lớn nhất · 21/10'), findsOneWidget);
      expect(find.text('−1.450.000'), findsOneWidget);
    });

    testWidgets('a period with no income or spending says so', (t) async {
      await _open(t, cases: StubReportCases(flowEmpty: true));
      expect(find.text('Dòng tiền trong tháng'), findsOneWidget);
      expect(find.text('Chưa có thu chi trong kỳ này'), findsOneWidget);
      expect(find.textContaining('cộng dồn'), findsNothing);
      expect(find.textContaining('Thu lớn nhất'), findsNothing);
    });

    testWidgets('a cash flow that could not load hides only its card', (
      t,
    ) async {
      await _open(t, cases: StubReportCases(flowFails: true));
      expect(find.text('Dòng tiền trong tháng'), findsNothing);
      expect(find.text('Xu hướng chi'), findsOneWidget);
      expect(find.text('Tổng thu nhập'), findsOneWidget);
    });
  });

  group('debt and investment cards', () {
    testWidgets('show what moved in the month, not the totals', (t) async {
      await _open(t);
      expect(find.text('Nợ và vay'), findsOneWidget);
      expect(find.text('Dư nợ thay đổi'), findsOneWidget);
      expect(find.textContaining('−3.600.000'), findsOneWidget);
      expect(find.text('Đang giảm'), findsOneWidget);
      expect(find.text('Đã trả trong kỳ'), findsOneWidget);
      expect(find.text('6.700.000'), findsOneWidget);
      expect(find.text('Vay và dùng thẻ thêm'), findsOneWidget);
      expect(find.text('3.100.000'), findsOneWidget);
      expect(
        find.text('Sắp phải trả: 5.200.000 ₫ khoản vay vào 05/11'),
        findsOneWidget,
      );
      expect(find.text('Đầu tư'), findsOneWidget);
      expect(find.text('Lãi/lỗ trong kỳ'), findsOneWidget);
      expect(find.textContaining('−1.350.000'), findsOneWidget);
      expect(find.text('▼ 0,9%'), findsOneWidget);
      expect(find.text('Đầu tư thêm'), findsOneWidget);
      expect(find.text('Đã rút hoặc bán'), findsOneWidget);
      expect(find.text('Trong tháng 10'), findsNWidgets(2));
      expect(find.text('Chi tiết'), findsNWidgets(2));
    });

    testWidgets('are left out when there is nothing, or it failed to load', (
      t,
    ) async {
      await _open(t, cases: StubReportCases(noHoldings: true));
      expect(find.text('Nợ và vay'), findsNothing);
      expect(find.text('Lãi/lỗ trong kỳ'), findsNothing);
      expect(find.text('Cơ cấu'), findsOneWidget);
      await _open(t, cases: StubReportCases(holdingsFail: true));
      expect(find.text('Nợ và vay'), findsNothing);
      expect(find.text('Lãi/lỗ trong kỳ'), findsNothing);
      expect(find.text('Tổng thu nhập'), findsOneWidget);
    });
  });

  group('insights card', () {
    testWidgets('lists two findings of the running month and links on', (
      t,
    ) async {
      await _open(t, insights: StubInsightsViewModel(period: _october));
      expect(find.text('Nhận định'), findsOneWidget);
      expect(find.text('Tháng này'), findsOneWidget);
      expect(
        find.text('Ăn uống tăng 35% so với cùng kỳ tháng trước'),
        findsOneWidget,
      );
      expect(find.text('Mua sắm đã dùng 90% ngân sách'), findsOneWidget);
      // Only two of the four, in the order Phân tích has them.
      expect(find.textContaining('Điện máy Xanh'), findsNothing);
      expect(find.text('Xem tất cả ở Phân tích'), findsOneWidget);
    });

    testWidgets(
      'is hidden for another month, with nothing, or when not wired',
      (t) async {
        await _open(
          t,
          insights: StubInsightsViewModel(
            period: const InsightPeriod(
              from: '2026-11-01',
              to: '2026-11-30',
              today: '2026-11-10',
            ),
          ),
        );
        expect(find.text('Nhận định'), findsNothing);
        await _open(
          t,
          insights: StubInsightsViewModel(items: const [], period: _october),
        );
        expect(find.text('Nhận định'), findsNothing);
        await _open(t, insights: StubInsightsViewModel(period: null));
        expect(find.text('Nhận định'), findsNothing);
        await _open(t);
        expect(find.text('Nhận định'), findsNothing);
        expect(find.text('Tổng thu nhập'), findsOneWidget);
      },
    );
  });

  group('budget', () {
    testWidgets('keeps its place and the old month-review row is gone', (
      t,
    ) async {
      await _open(t);
      expect(find.text('Đặt ngân sách tháng'), findsOneWidget);
      expect(find.text('Xem bản soát tháng'), findsNothing);
    });
  });

  group('breakdown', () {
    testWidgets('is titled Cơ cấu and offers the whole list per tab', (
      t,
    ) async {
      await _open(t);
      expect(find.text('Cơ cấu'), findsOneWidget);
      expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
      expect(find.text('Xem toàn bộ cơ cấu chi tiêu'), findsOneWidget);
      await t.tap(find.text('Thu').last);
      await t.pumpAndSettle();
      expect(find.text('Thu nhập theo danh mục'), findsOneWidget);
      expect(find.text('Xem toàn bộ cơ cấu thu nhập'), findsOneWidget);
      await t.tap(find.text('Ví'));
      await t.pumpAndSettle();
      expect(find.text('Thu chi theo ví'), findsOneWidget);
      // The wallets are all listed already: no "see all" there.
      expect(find.textContaining('Xem toàn bộ'), findsNothing);
    });

    testWidgets('the button opens every category with its share', (t) async {
      _tall(t, size: const Size(390, 2600));
      // Registers the stubbed model; the router below supplies both routes.
      await f1App(const SizedBox());
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (context, state) => const ReportPage()),
          GoRoute(
            path: '/reports/breakdown',
            builder: (context, state) =>
                ReportBreakdownPage(args: state.extra! as BreakdownPageArgs),
          ),
        ],
      );
      await t.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          routerConfig: router,
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Xem toàn bộ cơ cấu chi tiêu'));
      await t.pumpAndSettle();
      expect(find.text('Cơ cấu chi tiêu'), findsOneWidget);
      expect(find.text('Tổng chi tiêu'), findsOneWidget);
      expect(find.textContaining('9.320.000'), findsOneWidget);
      expect(find.text('9 DANH MỤC'), findsOneWidget);
      expect(find.text('Chi nhiều nhất trước'), findsOneWidget);
      // Every parent is listed: Ăn uống (two children folded), then the rest.
      for (final name in [
        'Ăn uống',
        'Nhà ở',
        'Đi lại',
        'Mua sắm',
        'Sức khoẻ',
        'Giải trí',
        'Giáo dục',
        'Quà tặng',
        'Linh tinh',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Khác'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('every new card fits a narrow, large-text screen', (t) async {
    for (final scale in [1.3, 2.0]) {
      await _open(
        t,
        insights: StubInsightsViewModel(period: _october),
        scale: scale,
        size: const Size(320, 640),
      );
      expect(t.takeException(), isNull, reason: 'x$scale');
      for (var i = 0; i < 8; i++) {
        await t.drag(find.byType(ListView).first, const Offset(0, -700));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: 'x$scale scroll $i');
      }
    }
  });
}
