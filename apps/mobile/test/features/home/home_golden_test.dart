import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'home_test_app.dart';

// Rendered on macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/home/home_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  const cases = {
    'ready': false,
    'ready_dark': true,
    'hidden': false,
    'multi': false,
    'debt': false,
    'newMonth': false,
    'loading': false,
    'offline': false,
    'error': false,
    'firstRun': false,
  };
  for (final MapEntry(key: name, value: dark) in cases.entries) {
    testWidgets('overview $name', skip: !Platform.isMacOS, (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final state = name.replaceAll('_dark', '');
      await tester.pumpWidget(await homeApp(homeState(state), dark: dark));
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/overview_$name.png'),
      );
    });
  }
}
