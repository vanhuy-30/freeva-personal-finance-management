import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/presentation/pages/investments_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'investment_stub.dart';

// macOS only (see core_widgets_golden_test.dart). Boards: PList and PEmpty
// (group P, screens 1 and 2). Update:
// flutter test --update-goldens test/features/investments/investment_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    String name, {
    bool dark = false,
    FakeInvestmentUseCases? cases,
    double height = 1520,
  }) async {
    t.view.physicalSize = Size(390, height);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => investmentApp(const InvestmentsPage(), dark: dark, cases: cases),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/investments_$name.png'),
    );
  }

  testWidgets('list', skip: !Platform.isMacOS, (t) => shot(t, 'list'));
  testWidgets(
    'list dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'dark', dark: true),
  );
  testWidgets('empty', skip: !Platform.isMacOS, (t) {
    final fake = FakeInvestmentUseCases()
      ..items = []
      ..summaryValue = const InvestmentSummary();
    return shot(t, 'empty', cases: fake, height: 844);
  });
}
