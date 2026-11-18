import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/widgets/empty_state.dart';

import 'widget_test_app.dart';

Widget _body() => const Center(
  child: RepaintBoundary(
    child: EmptyState(
      title: 'Chưa có ví',
      message: 'Thêm ví đầu tiên để bắt đầu.',
      actionLabel: 'Thêm ví',
    ),
  ),
);

void main() {
  setUpAll(loadTestFonts);

  for (final dark in [false, true]) {
    testWidgets(
      'golden: empty state ${dark ? 'dark' : 'light'}',
      skip: !Platform.isMacOS,
      (tester) async {
        tester.view.physicalSize = const Size(390, 520);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(testApp(_body(), dark: dark));
        await tester.pump(const Duration(milliseconds: 800));
        await expectLater(
          find.byType(EmptyState),
          matchesGoldenFile('goldens/empty_state${dark ? '_dark' : ''}.png'),
        );
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('moves for a few turns, then rests', (tester) async {
    await tester.pumpWidget(testApp(_body()));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('does not move with reduced motion', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: testApp(_body()),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
