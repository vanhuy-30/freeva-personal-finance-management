import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/widgets/freeva_switch.dart';
import 'package:mobile/features/forecast/presentation/pages/forecast_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'forecast_stub.dart';

// macOS only (see core_widgets_golden_test.dart). Board: Forecast.dc.html
// (group N, screen 2), read with tool/design_compare. Update:
// flutter test --update-goldens test/features/forecast/forecast_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<ForecastHarness> shot(
    WidgetTester t,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 1000),
    bool schoolOff = true,
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => forecastApp(const ForecastPage(), dark: dark, scale: scale),
    ))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (schoolOff) {
      await t.tap(find.byType(FreevaSwitch).at(3));
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 400));
    }
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/forecast_$name.png'),
    );
    return h;
  }

  testWidgets('forecast', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'main', schoolOff: false);
  });
  testWidgets('forecast school off', skip: !Platform.isMacOS, (t) async {
    final h = await shot(t, 'school_off');
    expect(h.cases.calls.last.excluded, {'school'});
  });
  testWidgets('forecast dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'dark', dark: true, schoolOff: false);
  });
  testWidgets('forecast 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(t, 'scaled', scale: 1.3, schoolOff: false);
  });
  testWidgets('forecast 12 months', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'twelve',
      schoolOff: false,
      then: () async {
        await t.tap(find.text('12 tháng'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('balance sheet', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      'balance',
      schoolOff: false,
      then: () async {
        await t.tap(find.text('Sửa'));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });

  testWidgets('editing the balance sends the typed amount', (t) async {
    t.view.physicalSize = const Size(390, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(() => forecastApp(const ForecastPage())))!;
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Cuối tháng 1 còn khoảng'), findsOneWidget);
    await t.tap(find.text('Sửa'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.enterText(find.byType(TextField), '10000000');
    await t.pump();
    await t.tap(find.text('Dùng số này'));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(h.cases.calls.last.start, BigInt.from(10000000));
    expect(find.textContaining('bạn nhập'), findsOneWidget);
  });
}
