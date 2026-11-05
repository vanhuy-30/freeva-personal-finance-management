import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/budgets/presentation/widgets/threshold_sheet.dart';

Widget _app(List<int> initial, ValueChanged<List<int>?> onResult, bool dark) {
  return MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async =>
                onResult(await showThresholdSheet(context, selected: initial)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _open(WidgetTester t) async {
  await t.tap(find.text('open'));
  await t.pumpAndSettle();
}

void main() {
  test('default thresholds are 80 and 100', () {
    expect(defaultAlertThresholds, [80, 100]);
  });

  group('toggleThreshold', () {
    test('adds in order and removes', () {
      expect(toggleThreshold([80, 100], 70), [70, 80, 100]);
      expect(toggleThreshold([70, 80, 100], 80), [70, 100]);
    });
    test('ignores a fifth level', () {
      expect(toggleThreshold([60, 70, 80, 100], 90), [60, 70, 80, 100]);
    });
    test('keeps at least one level', () {
      expect(toggleThreshold([100], 100), [100]);
    });
  });

  testWidgets('chips toggle and Lưu returns the levels', (t) async {
    List<int>? result;
    await t.pumpWidget(_app(const [80, 100], (v) => result = v, false));
    await _open(t);
    expect(find.text('Báo khi đã dùng'), findsOneWidget);
    expect(find.text('Mặc định 80% và 100%.'), findsOneWidget);
    await t.tap(find.text('70%'));
    await t.pump();
    await t.tap(find.text('Lưu'));
    await t.pumpAndSettle();
    expect(result, [70, 80, 100]);
  });

  testWidgets('a saved level outside the chips stays selectable', (t) async {
    await t.pumpWidget(_app(const [50, 100], (_) {}, false));
    await _open(t);
    expect(find.text('50%'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets('golden ${dark ? 'dark' : 'light'}', skip: !Platform.isMacOS, (
      t,
    ) async {
      t.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(const [80, 100], (_) {}, dark));
      await _open(t);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/n4_thresholds${dark ? '_dark' : ''}.png'),
      );
    });
  }
}
