import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/presentation/pages/investment_editor_page.dart';
import 'package:mobile/features/investments/presentation/pages/investment_kind_page.dart';
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
    Widget page = const InvestmentsPage(),
  }) async {
    t.view.physicalSize = Size(390, height);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => investmentApp(page, dark: dark, cases: cases),
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

  testWidgets('editor gold', skip: !Platform.isMacOS, (t) async {
    t.view.physicalSize = const Size(390, 1070);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => investmentApp(const InvestmentEditorPage()),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'Vàng SJC');
    await t.enterText(fields.at(1), '3');
    await t.enterText(fields.at(2), '7200000');
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/investments_editor_gold.png'),
    );
  });

  testWidgets('editor deposit', skip: !Platform.isMacOS, (t) async {
    t.view.physicalSize = const Size(390, 930);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => investmentApp(
        const InvestmentEditorPage(kind: InvestmentKind.savingsDeposit),
      ),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'Techcombank 6 tháng');
    await t.enterText(fields.at(1), '30000000');
    await t.enterText(fields.at(2), '5,8');
    await t.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/investments_editor_deposit.png'),
    );
  });

  Future<void> kindShot(
    WidgetTester t,
    String name, {
    String? tap,
    bool dark = false,
  }) async {
    t.view.physicalSize = const Size(390, 1900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => investmentApp(
        const InvestmentKindPage(kind: InvestmentKind.gold),
        dark: dark,
      ),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pumpAndSettle();
    if (tap != null) {
      await t.tap(find.text(tap).first);
      await t.pumpAndSettle();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/investments_$name.png'),
    );
  }

  testWidgets('kind', skip: !Platform.isMacOS, (t) => kindShot(t, 'kind'));
  testWidgets(
    'kind dark',
    skip: !Platform.isMacOS,
    (t) => kindShot(t, 'kind_dark', dark: true),
  );
  testWidgets(
    'sell sheet',
    skip: !Platform.isMacOS,
    (t) => kindShot(t, 'sell', tap: 'Bán'),
  );
  testWidgets(
    'price sheet',
    skip: !Platform.isMacOS,
    (t) => kindShot(t, 'price', tap: 'Cập nhật giá'),
  );
}
