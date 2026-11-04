import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/recurring/presentation/pages/recurring_editor_page.dart';
import 'package:mobile/features/recurring/presentation/pages/recurring_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'recurring_stub.dart';

// macOS only (see core_widgets_golden_test.dart). The board each golden is
// read against is named in the test; compare with tool/design_compare
// (group L). Update:
// flutter test --update-goldens test/features/recurring/recurring_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<RecurringHarness> shot(
    WidgetTester t,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 900),
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => recurringApp(page, dark: dark, scale: scale),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/rec_$name.png'),
    );
    return h;
  }

  // RecList
  testWidgets('list', skip: !Platform.isMacOS, (t) async {
    await shot(t, const RecurringPage(), 'list');
  });
  testWidgets('list dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, const RecurringPage(), 'list_dark', dark: true);
  });
  testWidgets('list 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(t, const RecurringPage(), 'list_scaled', scale: 1.3);
  });

  // RecEdit
  testWidgets('add remind', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringEditorPage(),
      'add_remind',
      then: () async {
        await t.enterText(find.byType(TextField).at(0), 'Tiền điện');
        await t.enterText(find.byType(TextField).at(1), '850000');
        await t.tap(find.text('Số tiền mỗi kỳ có thể khác'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('add remind dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringEditorPage(),
      'add_remind_dark',
      dark: true,
      then: () async {
        await t.enterText(find.byType(TextField).at(0), 'Tiền điện');
        await t.enterText(find.byType(TextField).at(1), '850000');
      },
    );
  });
  testWidgets('add remind 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringEditorPage(),
      'add_remind_scaled',
      scale: 1.3,
      size: const Size(390, 1100),
    );
  });

  // RecEditAuto
  testWidgets('edit auto', skip: !Platform.isMacOS, (t) async {
    await shot(t, const RecurringEditorPage(ruleId: 'rent'), 'edit_auto');
  });
  testWidgets('edit auto dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringEditorPage(ruleId: 'rent'),
      'edit_auto_dark',
      dark: true,
    );
  });

  // BillPaid
  testWidgets('paid sheet', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringPage(),
      'paid_sheet',
      then: () async {
        await t.tap(find.text('Đã trả').at(1));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
        await t.enterText(find.byType(TextField), '872000');
        await t.pump();
      },
    );
  });
  testWidgets('paid sheet dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const RecurringPage(),
      'paid_sheet_dark',
      dark: true,
      then: () async {
        await t.tap(find.text('Đã trả').at(1));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
}
