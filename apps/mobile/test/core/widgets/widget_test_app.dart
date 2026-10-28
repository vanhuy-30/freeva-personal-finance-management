import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';

/// Wraps [child] in a themed, localised app for widget tests.
Widget testApp(
  Widget child, {
  bool dark = false,
  Locale locale = const Locale('vi'),
}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: locale,
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: child),
);

/// Loads Inter and Lucide so goldens show real glyphs instead of boxes.
Future<void> loadTestFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final asset in assets) {
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }

  await load('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
  ]);
  await load('Lucide175', ['assets/fonts/Lucide175.ttf']);
  await load('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
}
