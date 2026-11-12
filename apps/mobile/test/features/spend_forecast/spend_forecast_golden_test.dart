import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/spend_forecast/presentation/pages/spend_forecast_page.dart';
import 'package:mobile/features/spend_forecast/presentation/viewmodels/spend_forecast_view_model.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'spend_forecast_fakes.dart';

// Board S.3 SpendForecast. macOS only.
// Update: flutter test --update-goldens test/features/spend_forecast/spend_forecast_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  for (final dark in [false, true]) {
    final name = dark ? 's3_spend_forecast_dark' : 's3_spend_forecast';
    testWidgets('S.3 $name', skip: !Platform.isMacOS, (t) async {
      t.view.physicalSize = const Size(390, 860);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      getIt.registerSingleton<SpendForecastViewModel>(
        StubSpendForecastViewModel(forecast: boardForecast()),
      );
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: const SpendForecastPage(),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
