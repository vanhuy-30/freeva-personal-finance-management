import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/transaction_import/domain/import_models.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'import_stub.dart';

// macOS only (see core_widgets_golden_test.dart). Boards: ImportSource,
// ImportColumns, ImportMap, ImportPreview, ImportDone (nhóm O).
// Update: flutter test --update-goldens test/features/transaction_import/import_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    String name, {
    required List<ImportPreview> plans,
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function(ImportHarness h)? drive,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = ImportHarness.create(plans);
    await t.pumpWidget(importApp(h, dark: dark, scale: scale));
    await t.pump(const Duration(milliseconds: 400));
    if (drive != null) {
      await t.runAsync(() => drive(h));
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 400));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/import_$name.png'),
    );
  }

  final mapPlan = plan(
    ready: 0,
    duplicate: 0,
    invalid: 0,
    rows: [],
    wallets: ['Vi tien mat', 'Techcombank'],
    categories: ['An sang', 'Xang xe', 'Shopping', 'Luong'],
  );

  Future<void> toMap(ImportHarness h) async {
    await h.model.load();
    await h.model.chooseFile();
    h.model.mapWallet('Techcombank', 'tcb');
    h.model.mapCategory('An sang', 'food');
  }

  Future<void> toPreview(ImportHarness h) async {
    await h.model.load();
    await h.model.chooseFile();
  }

  Future<void> toDone(ImportHarness h) async {
    await toPreview(h);
    await h.model.commit();
  }

  Future<void> toColumns(ImportHarness h) async {
    await h.model.load();
    h.model.selectSource(ImportSource.other);
    await h.model.chooseFile();
    h.model.mapColumn(ImportField.notes, null);
  }

  testWidgets(
    'source',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'source', plans: [plan()]),
  );
  testWidgets(
    'source dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'source_dark', plans: [plan()], dark: true),
  );
  testWidgets(
    'source with a problem',
    skip: !Platform.isMacOS,
    (t) => shot(
      t,
      'source_problem',
      plans: [plan()],
      drive: (h) async {
        h.picker.text = '';
        await h.model.chooseFile();
      },
    ),
  );
  testWidgets(
    'columns',
    skip: !Platform.isMacOS,
    (t) => shot(
      t,
      'columns',
      plans: [plan()],
      size: const Size(390, 900),
      drive: toColumns,
    ),
  );
  testWidgets(
    'map',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'map', plans: [mapPlan], drive: toMap),
  );
  testWidgets(
    'map dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'map_dark', plans: [mapPlan], drive: toMap, dark: true),
  );
  testWidgets(
    'preview',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'preview', plans: [plan()], drive: toPreview),
  );
  testWidgets(
    'preview dark',
    skip: !Platform.isMacOS,
    (t) =>
        shot(t, 'preview_dark', plans: [plan()], drive: toPreview, dark: true),
  );
  testWidgets(
    'preview 320 pt 1.3x',
    skip: !Platform.isMacOS,
    (t) => shot(
      t,
      'preview_320_13',
      plans: [plan()],
      drive: toPreview,
      scale: 1.3,
      size: const Size(320, 760),
    ),
  );
  testWidgets(
    'done',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'done', plans: [plan()], drive: toDone),
  );
  testWidgets(
    'done dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'done_dark', plans: [plan()], drive: toDone, dark: true),
  );
}
