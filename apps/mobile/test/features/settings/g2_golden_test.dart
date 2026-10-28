import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/feedback/domain/feedback.dart';
import 'package:mobile/features/feedback/presentation/pages/feedback_page.dart';
import 'package:mobile/features/settings/presentation/pages/faq_page.dart';
import 'package:mobile/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:mobile/features/tags/domain/tag_use_cases.dart';
import 'package:mobile/features/tags/presentation/pages/tag_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'g1_harness.dart';
import 'g2_test.dart' show FakeFeedback, FakeTags;

// macOS only. Update: flutter test --update-goldens test/features/settings/g2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final g = (await t.runAsync(G1.create))!;
    addTearDown(g.dispose);
    getIt
      ..registerSingleton<TagUseCases>(FakeTags())
      ..registerSingleton<FeedbackUseCases>(FakeFeedback());
    await t.pumpWidget(g.app(page, dark: dark, scale: scale));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/g2_$name.png'),
    );
  }

  testWidgets('tags', skip: !Platform.isMacOS, (t) async {
    await shot(t, const TagPage(), 'tags');
  });
  testWidgets('feedback', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const FeedbackPage(),
      'feedback',
      size: const Size(390, 1000),
      then: () async {
        await t.enterText(
          find.byType(TextField),
          'Mong có nhắc ghi chi buổi tối.',
        );
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('feedback compact', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const FeedbackPage(),
      'feedback_compact',
      scale: 1.3,
      size: const Size(320, 1500),
    );
  });
  testWidgets('thanks', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const FeedbackPage(),
      'thanks',
      then: () async {
        await t.enterText(find.byType(TextField), 'Cảm ơn');
        await t.pump();
        await t.tap(find.text('Gửi góp ý'));
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('faq', skip: !Platform.isMacOS, (t) async {
    await shot(t, const FaqPage(), 'faq');
  });
  testWidgets('notifications', skip: !Platform.isMacOS, (t) async {
    await shot(t, const NotificationSettingsPage(), 'notify');
  });
}
