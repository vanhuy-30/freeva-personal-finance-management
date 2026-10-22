import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile/core/theme/tokens.g.dart';
import 'package:mobile/core/widgets/freeva_bottom_nav.dart';
import 'package:mobile/core/widgets/freeva_button.dart';
import 'package:mobile/core/widgets/freeva_segmented.dart';
import 'package:mobile/core/widgets/money_display.dart';
import 'package:mobile/core/widgets/nav_notch_painter.dart';

import 'widget_test_app.dart';

void main() {
  const items = [
    FreevaNavItem(icon: LucideIcons.house, label: 'Tổng quan'),
    FreevaNavItem(icon: LucideIcons.list, label: 'Giao dịch'),
    FreevaNavItem(icon: LucideIcons.chartPie, label: 'Báo cáo'),
    FreevaNavItem(icon: LucideIcons.user, label: 'Cá nhân'),
  ];

  testWidgets('bottom nav selects tabs and opens record from +', (
    tester,
  ) async {
    int? selected;
    var added = 0;
    await tester.pumpWidget(
      testApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: FreevaBottomNav(
            items: items,
            currentIndex: 0,
            onSelect: (i) => selected = i,
            onAdd: () => added++,
            addLabel: 'Ghi giao dịch',
          ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Báo cáo'));
    expect(selected, 2);
    await tester.tap(find.bySemanticsLabel('Ghi giao dịch'));
    expect(added, 1);
    final current = tester.getSemantics(find.bySemanticsLabel('Tổng quan'));
    expect(current.flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.takeException(), isNull);
  });

  test('nav notch is cut out of the bar around the + button', () {
    const size = Size(350, FreevaComponent.navHeight);
    const centerY = FreevaComponent.navHeight / 2 - FreevaComponent.navFabLift;
    const painter = NavNotchPainter(
      color: Colors.white,
      shadows: [],
      notchCenterY: centerY,
      notchRadius: FreevaComponent.navFabSize / 2 + FreevaComponent.navFabNotch,
    );
    final shape = painter.shape(size);
    expect(shape.contains(const Offset(175, 2)), isFalse);
    expect(shape.contains(const Offset(175, 50)), isTrue);
    expect(shape.contains(const Offset(60, 2)), isTrue);
  });

  testWidgets('hidden money masks the number and reads balance hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        MoneyDisplay(
          minor: BigInt.from(48250000),
          currency: 'VND',
          hidden: true,
        ),
      ),
    );
    expect(find.textContaining('48'), findsNothing);
    expect(find.bySemanticsLabel('số dư đã ẩn'), findsOneWidget);
  });

  testWidgets('income is signed + and expense −, without ₫ in lists', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            MoneyDisplay(
              minor: BigInt.from(18500000),
              currency: 'VND',
              tone: MoneyTone.income,
              showCurrency: false,
            ),
            MoneyDisplay(
              minor: BigInt.from(65000),
              currency: 'VND',
              tone: MoneyTone.expense,
              showCurrency: false,
            ),
          ],
        ),
      ),
    );
    expect(find.text('+18.500.000'), findsOneWidget);
    expect(find.text('−65.000'), findsOneWidget);
    expect(find.textContaining('₫'), findsNothing);
  });

  testWidgets('loading button keeps its size and ignores taps', (tester) async {
    var taps = 0;
    Widget build(bool loading) => testApp(
      Center(
        child: FreevaButton(
          label: 'Lưu khoản chi',
          loading: loading,
          onPressed: () => taps++,
        ),
      ),
    );
    await tester.pumpWidget(build(false));
    final idle = tester.getSize(find.byType(TextButton));
    await tester.pumpWidget(build(true));
    expect(tester.getSize(find.byType(TextButton)).height, idle.height);
    await tester.tap(find.byType(TextButton));
    expect(taps, 0);
    expect(idle.height, FreevaSize.button);
  });

  testWidgets('segmented reports the tapped value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      testApp(
        Center(
          child: FreevaSegmented<String>(
            segments: const [
              FreevaSegment('w', 'Tuần'),
              FreevaSegment('m', 'Tháng'),
            ],
            selected: 'm',
            onChanged: (v) => picked = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tuần'));
    expect(picked, 'w');
  });
}
