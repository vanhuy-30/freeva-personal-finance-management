import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:mobile/features/settings/presentation/pages/security_page.dart';
import 'package:mobile/features/settings/presentation/pages/sessions_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'g1_harness.dart';

// macOS only. Update: flutter test --update-goldens test/features/settings/g1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester t,
    Widget Function(G1 g) page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 1500),
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final g = (await t.runAsync(G1.create))!;
    addTearDown(g.dispose);
    await t.pumpWidget(g.app(page(g), dark: dark, scale: scale));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/g1_$name.png'),
    );
  }

  testWidgets('me', skip: !Platform.isMacOS, (t) async {
    await shot(t, (_) => const SettingsPage(), 'me');
  });
  testWidgets('me dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, (_) => const SettingsPage(), 'me_dark', dark: true);
  });
  testWidgets('me compact', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const SettingsPage(),
      'me_compact',
      scale: 1.3,
      size: const Size(320, 2000),
    );
  });
  testWidgets('theme sheet', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const SettingsPage(),
      'theme',
      size: const Size(390, 844),
      then: () async {
        await t.tap(find.text('Giao diện'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('logout popup', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const SettingsPage(),
      'logout',
      size: const Size(390, 2200),
      then: () async {
        await t.tap(find.text('Đăng xuất'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('profile', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const ProfilePage(),
      'profile',
      size: const Size(390, 844),
    );
  });
  testWidgets('security', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const SecurityPage(),
      'security',
      size: const Size(390, 844),
    );
  });
  testWidgets('sessions', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      (_) => const SessionsPage(),
      'sessions',
      size: const Size(390, 844),
    );
  });
}
