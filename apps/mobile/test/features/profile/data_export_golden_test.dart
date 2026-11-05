import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/profile/presentation/pages/data_export_page.dart';
import 'package:mobile/features/profile/presentation/viewmodels/data_export_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'data_export_stub.dart';

// macOS only (see core_widgets_golden_test.dart). Board: DataExport (nhóm O).
// Update: flutter test --update-goldens test/features/profile/data_export_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function(ExportHarness h)? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final (h, app) = (await t.runAsync(
      () => exportApp(const DataExportPage(), dark: dark, scale: scale),
    ))!;
    await t.pumpWidget(app);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then(h);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/data_export_$name.png'),
    );
  }

  testWidgets('table', skip: !Platform.isMacOS, (t) => shot(t, 'table'));
  testWidgets(
    'table dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'table_dark', dark: true),
  );
  testWidgets(
    'table 320 pt 1.3x',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'table_320_13', scale: 1.3, size: const Size(320, 760)),
  );
  testWidgets(
    'too many',
    skip: !Platform.isMacOS,
    (t) => shot(
      t,
      'too_many',
      then: (h) async {
        h.transactions.total = 50001;
        h.model.selectWallets({'vcb'});
        await t.pump(const Duration(milliseconds: 100));
      },
    ),
  );
  testWidgets('full copy', skip: !Platform.isMacOS, (t) {
    return shot(
      t,
      'full',
      then: (h) async {
        h.model.selectKind(ExportKind.fullCopy);
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
}
