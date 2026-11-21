import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/insights/domain/insight.dart';
import 'package:mobile/features/reports/domain/category_detail.dart';
import 'package:mobile/features/reports/domain/report_breakdown.dart';
import 'package:mobile/features/reports/presentation/pages/report_breakdown_page.dart';
import 'package:mobile/features/reports/presentation/pages/report_page.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../insights/insights_fakes.dart' show StubInsightsViewModel;
import 'f1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/reports/f1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 1500),
    StubReportCases? cases,
    bool insights = true,
    Widget page = const ReportPage(),
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await f1App(
        page,
        dark: dark,
        scale: scale,
        cases: cases,
        insights: insights
            ? StubInsightsViewModel(
                period: const InsightPeriod(
                  from: '2026-10-01',
                  to: '2026-10-31',
                  today: '2026-10-21',
                ),
              )
            : null,
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/f1_$name.png'),
    );
  }

  testWidgets('month', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, 'month');
  });
  testWidgets('month dark', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, 'month_dark', dark: true);
  });
  testWidgets('month compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'month_compact',
      scale: 1.3,
      size: const Size(320, 2000),
    );
  });
  testWidgets('wallets', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'wallets',
      size: const Size(390, 1500),
      then: () async {
        await tester.tap(find.text('Ví'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('empty period', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'empty',
      size: const Size(390, 844),
      then: () async {
        await tester.tap(find.byTooltip('Kỳ trước'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('custom range', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'range',
      size: const Size(390, 1500),
      then: () async {
        await getIt<ReportViewModel>().applyRange('2026-10-06', '2026-10-19');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('no cash flow', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'flow_empty',
      cases: StubReportCases(flowEmpty: true),
      insights: false,
    );
  });
  testWidgets('whole breakdown', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'breakdown',
      size: const Size(390, 1000),
      page: ReportBreakdownPage(
        args: BreakdownPageArgs(
          report: october(),
          currency: 'VND',
          digits: 0,
          kind: BreakdownKind.expense,
        ),
      ),
    );
  });
  testWidgets('whole breakdown dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      'breakdown_dark',
      dark: true,
      size: const Size(390, 1000),
      page: ReportBreakdownPage(
        args: BreakdownPageArgs(
          report: october(),
          currency: 'VND',
          digits: 0,
          kind: BreakdownKind.expense,
        ),
      ),
    );
  });
}
