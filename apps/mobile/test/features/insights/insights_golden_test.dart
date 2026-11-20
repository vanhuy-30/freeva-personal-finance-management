import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/insights/presentation/pages/insights_page.dart';
import 'package:mobile/features/insights/presentation/viewmodels/insights_view_model.dart';
import 'package:mobile/features/spend_forecast/presentation/viewmodels/spend_forecast_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart';
import '../home/home_fakes.dart';
import '../home/home_test_app.dart';
import '../spend_forecast/spend_forecast_fakes.dart'
    show StubSpendForecastViewModel, boardForecast;
import 'insights_fakes.dart';

/// Board S.1 InsHome: the PA 3 Overview (10/11) with the "Đáng chú ý" card
/// under the tiles.
StubHomeViewModel boardHome() => StubHomeViewModel(data: pa3Overview())
  ..today = DateTime(2026, 11, 10, 9, 30);

// Boards S.1 InsHome (Overview card) and S.2 InsAnalysis (forecast card from
// MOB-P5-E06 on top of the list). macOS only.
// Update: flutter test --update-goldens test/features/insights/insights_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  for (final dark in [false, true]) {
    final name = dark ? 's1_ins_home_dark' : 's1_ins_home';
    testWidgets('S.1 $name', skip: !Platform.isMacOS, (t) async {
      t.view.physicalSize = const Size(390, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final app = await homeApp(boardHome(), dark: dark, goals: pa3Goals());
      getIt.registerSingleton<InsightsViewModel>(StubInsightsViewModel());
      await t.pumpWidget(app);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }

  testWidgets('S.2 list', skip: !Platform.isMacOS, (t) async {
    t.view.physicalSize = const Size(390, 960);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    getIt
      ..registerSingleton<InsightsViewModel>(StubInsightsViewModel())
      ..registerSingleton<SpendForecastViewModel>(
        StubSpendForecastViewModel(forecast: boardForecast()),
      );
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const InsightsPage(),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/s2_ins_analysis.png'),
    );
  });
}
