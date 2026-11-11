import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/settings/presentation/widgets/app_settings_group.dart';

import '../settings/g1_harness.dart';
import 'auto_suggest_fakes.dart';

void main() {
  Future<void> pump(WidgetTester t, StubAutoSuggestViewModel model) async {
    t.view.physicalSize = const Size(390, 1200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final g = (await t.runAsync(G1.create))!;
    addTearDown(g.dispose);
    await t.pumpWidget(
      g.app(
        Scaffold(
          body: AppSettingsGroup(
            settings: g.settings,
            profile: g.profile,
            autoSuggest: model,
          ),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('Cá nhân row shows only when a flag is on', (t) async {
    await pump(t, StubAutoSuggestViewModel(available: false));
    expect(find.text('Gợi ý tự động'), findsNothing);

    await pump(t, StubAutoSuggestViewModel(enabled: false));
    expect(find.text('Gợi ý tự động'), findsOneWidget);
    expect(find.text('Tắt'), findsOneWidget);
  });
}
