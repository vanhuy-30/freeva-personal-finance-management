import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/reports/domain/report_range.dart';
import 'package:mobile/features/reports/presentation/widgets/range_picker_dialog.dart';

/// Opens the popup from a button and collects what it returns.
class _Host extends StatelessWidget {
  const _Host({required this.result, this.initial = const RangeSelection()});

  final ValueChanged<RangeSelection?> result;
  final RangeSelection initial;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () async => result(
        await showRangePicker(context, today: '2026-10-21', initial: initial),
      ),
      child: const Text('mở'),
    ),
  );
}

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('vi'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: Scaffold(body: home),
  ),
);

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
  }

  testWidgets('picks two days, shows the summary and returns the range', (
    tester,
  ) async {
    RangeSelection? got;
    await tester.pumpWidget(_app(_Host(result: (r) => got = r)));
    await open(tester);
    expect(find.text('Chọn ngày đầu'), findsOneWidget);
    await tester.tap(find.text('Xem khoảng này'));
    await tester.pump();
    expect(got, isNull, reason: 'locked until both ends are chosen');
    await tester.tap(find.text('6'));
    await tester.pump();
    expect(find.text('Chọn ngày cuối'), findsOneWidget);
    await tester.tap(find.text('19'));
    await tester.pump();
    expect(find.text('06/10 – 19/10 · 14 ngày'), findsOneWidget);
    await tester.tap(find.text('Xem khoảng này'));
    await tester.pumpAndSettle();
    expect((got?.from, got?.to), ('2026-10-06', '2026-10-19'));
  });

  testWidgets('future days cannot be chosen; the next month is locked', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_Host(result: (_) {})));
    await open(tester);
    await tester.tap(find.text('25'));
    await tester.pump();
    expect(find.text('Chọn ngày đầu'), findsOneWidget);
    final next = find.bySemanticsLabel('Kỳ sau');
    expect(tester.getSemantics(next).flagsCollection.isEnabled.name, 'isFalse');
  });

  testWidgets('a quick pick fills the range and cancel returns nothing', (
    tester,
  ) async {
    RangeSelection? got = const RangeSelection(from: 'x');
    await tester.pumpWidget(_app(_Host(result: (r) => got = r)));
    await open(tester);
    await tester.tap(find.text('7 ngày qua'));
    await tester.pump();
    expect(find.text('15/10 – 21/10 · 7 ngày'), findsOneWidget);
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(got, isNull);
  });

  testWidgets('starts on the month of the current range and walks back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _Host(
          result: (_) {},
          initial: const RangeSelection(from: '2026-08-10', to: '2026-08-20'),
        ),
      ),
    );
    await open(tester);
    expect(find.text('Tháng 8, 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Kỳ trước'));
    await tester.pump();
    expect(find.text('Tháng 7, 2026'), findsOneWidget);
  });

  testWidgets('fits 320 pt at 1.3× and 2× text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final scale in [1.3, 2.0]) {
      await tester.pumpWidget(_app(_Host(result: (_) {}), scale: scale));
      await open(tester);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Huỷ'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
  });
}
