import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('supports reduced motion and large text on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: const SplashPage(),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Your money. Your freedom.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Leaving early must cancel the ticker and never navigate after disposal.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
