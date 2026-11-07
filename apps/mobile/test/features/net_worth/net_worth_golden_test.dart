import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/net_worth/presentation/pages/net_worth_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'net_worth_stub.dart';

// macOS only (see core_widgets_golden_test.dart). Board: QNetWorth.dc.html
// (group Q, screen 1), read with tool/design_compare. Update:
// flutter test --update-goldens test/features/net_worth/net_worth_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(WidgetTester t, String name, {bool dark = false}) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => netWorthApp(const NetWorthPage(), dark: dark),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/net_worth_$name.png'),
    );
  }

  testWidgets('net worth', skip: !Platform.isMacOS, (t) => shot(t, 'main'));
  testWidgets(
    'net worth dark',
    skip: !Platform.isMacOS,
    (t) => shot(t, 'dark', dark: true),
  );
}
