import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/categories/presentation/pages/category_editor_page.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'e1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/categories/e2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await e1App(page, dark: dark, scale: scale));
    await tester.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/e2_$name.png'),
    );
  }

  Widget editor({String? id}) => Builder(
    builder: (context) {
      final model = getIt<CategoryViewModel>();
      return CategoryEditorPage(
        model: model,
        category: id == null
            ? null
            : model.categories.firstWhere((c) => c.id == id),
      );
    },
  );

  Future<void> fillChild(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'Trà sữa');
    await tester.tap(find.text('Danh mục con'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Thuộc, Chọn danh mục chính'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Ăn uống').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Tím'));
    await tester.tap(find.bySemanticsLabel('Cà phê'));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('add', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, editor(), 'add', then: () => fillChild(tester));
  });
  testWidgets('add dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      editor(),
      'add_dark',
      dark: true,
      then: () => fillChild(tester),
    );
  });
  testWidgets('add compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      editor(),
      'add_compact',
      scale: 1.3,
      size: const Size(320, 700),
    );
  });
  testWidgets('parent sheet', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      editor(),
      'parent_sheet',
      then: () async {
        await tester.tap(find.text('Danh mục con'));
        await tester.pump();
        await tester.tap(find.bySemanticsLabel('Thuộc, Chọn danh mục chính'));
        await tester.pumpAndSettle();
      },
    );
  });
  testWidgets('edit', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, editor(id: 'snack'), 'edit');
  });
  testWidgets('edit blocked', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, editor(id: 'food'), 'edit_blocked');
  });
  testWidgets('icon sheet', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      editor(id: 'snack'),
      'icon_sheet',
      then: () async {
        await tester.tap(find.bySemanticsLabel(RegExp('^Biểu tượng, ')));
        await tester.pumpAndSettle();
      },
    );
  });
  testWidgets('delete popup', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      editor(id: 'snack'),
      'delete',
      then: () async {
        await tester.tap(find.text('Xoá'));
        await tester.pumpAndSettle();
      },
    );
  });
}
