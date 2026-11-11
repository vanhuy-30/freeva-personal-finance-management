import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/transaction_import/presentation/viewmodels/import_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'import_stub.dart';

// Boards R.2 SugImport and R.3 SugImportPick (390×844). macOS only.
// Update: flutter test --update-goldens test/features/transaction_import/r2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    String name, {
    bool dark = false,
    bool sheet = false,
  }) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = ImportHarness.create(
      [boardSuggestPlan()],
      wallets: boardWallets,
      catalog: boardCatalog,
    );
    await t.pumpWidget(importApp(h, dark: dark));
    await t.pump(const Duration(milliseconds: 400));
    await t.runAsync(() async {
      await h.model.load();
      await h.model.chooseFile();
      h.model.selectFilter(ImportFilter.suggested);
    });
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (sheet) {
      await t.tap(find.text('Highlands Coffee'));
      await t.pumpAndSettle();
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('R.2 Gợi ý filter', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'r2_sug_import');
  });
  testWidgets('R.2 Gợi ý filter dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'r2_sug_import_dark', dark: true);
  });
  testWidgets('R.3 change category sheet', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'r3_sug_import_pick', sheet: true);
  });
}
