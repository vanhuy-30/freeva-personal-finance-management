import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/reports/presentation/pages/report_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
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
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await f1App(const ReportPage(), dark: dark, scale: scale),
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
}
