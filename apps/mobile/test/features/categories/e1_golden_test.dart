import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/categories/presentation/pages/category_page.dart';
import 'package:mobile/features/categories/presentation/pages/hidden_categories_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'e1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/categories/e1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    Widget app,
    String name, {
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/e1_$name.png'),
    );
  }

  StubCategoryViewModel open() => StubCategoryViewModel(open: {'food'});

  testWidgets('list', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await e1App(const CategoryPage(), model: open()),
      'list',
    );
  });
  testWidgets('list dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await e1App(const CategoryPage(), model: open(), dark: true),
      'list_dark',
    );
  });
  testWidgets('list compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await e1App(const CategoryPage(), model: open(), scale: 1.3),
      'list_compact',
      size: const Size(320, 700),
    );
  });
  testWidgets('income tab', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await e1App(const CategoryPage()),
      'income',
      then: () async {
        await tester.tap(find.text('Thu'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('hidden', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, await e1App(const HiddenCategoriesPage()), 'hidden');
  });
}
