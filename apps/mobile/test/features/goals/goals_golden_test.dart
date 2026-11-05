import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:mobile/features/goals/presentation/pages/goal_editor_page.dart';
import 'package:mobile/features/goals/presentation/pages/goals_page.dart';
import 'package:mobile/features/goals/presentation/widgets/goals_home_block.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'goal_stub.dart';

// macOS only (see core_widgets_golden_test.dart). The board each golden is
// read against is named in the test; compare with tool/design_compare.
// Update: flutter test --update-goldens test/features/goals/goals_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<GoalHarness> shot(
    WidgetTester t,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 900),
    bool empty = false,
    Future<void> Function(GoalHarness h)? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => goalsApp(
        page,
        goals: empty ? const [] : null,
        income: BigInt.from(25000000),
        dark: dark,
        scale: scale,
      ),
    ))!;
    await t.pumpWidget(h.app);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then(h);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/goals_$name.png'),
    );
    return h;
  }

  // GoalEmpty
  testWidgets('empty', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalsPage(),
      'empty',
      empty: true,
      size: const Size(390, 844),
    );
  });
  testWidgets('empty dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalsPage(),
      'empty_dark',
      empty: true,
      dark: true,
      size: const Size(390, 844),
    );
  });

  // GoalList
  testWidgets('list', skip: !Platform.isMacOS, (t) async {
    await shot(t, const GoalsPage(), 'list');
  });
  testWidgets('list dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, const GoalsPage(), 'list_dark', dark: true);
  });
  testWidgets('list 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalsPage(),
      'list_scale',
      scale: 1.3,
      size: const Size(390, 1500),
    );
  });

  // GoalAdd
  Future<void> fillAdd(WidgetTester t) async {
    await t.enterText(find.byType(TextField).at(1), '120000000');
    await t.enterText(find.byType(TextField).at(2), '40000000');
    await t.pump();
  }

  testWidgets('add', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalEditorPage(initialKind: 'home'),
      'add',
      size: const Size(390, 844),
      then: (_) => fillAdd(t),
    );
  });
  testWidgets('add with date', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalEditorPage(initialKind: 'home'),
      'add_dated',
      size: const Size(390, 844),
      then: (_) async {
        await fillAdd(t);
        await t.tap(find.text('Chưa đặt'));
        await t.pumpAndSettle();
        await t.tap(find.text('25').first);
        await t.pumpAndSettle();
      },
    );
  });
  testWidgets('add dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalEditorPage(initialKind: 'home'),
      'add_dark',
      dark: true,
      size: const Size(390, 844),
      then: (_) => fillAdd(t),
    );
  });
  testWidgets('add 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalEditorPage(initialKind: 'home'),
      'add_scale',
      scale: 1.3,
      size: const Size(390, 1500),
      then: (_) => fillAdd(t),
    );
  });

  // GoalDetail
  testWidgets('detail', skip: !Platform.isMacOS, (t) async {
    await shot(t, const GoalDetailPage(goalId: 'home'), 'detail');
  });
  testWidgets('detail dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalDetailPage(goalId: 'home'),
      'detail_dark',
      dark: true,
    );
  });

  // GoalMove
  testWidgets('move in', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalDetailPage(goalId: 'home'),
      'move_in',
      then: (_) async {
        await t.tap(find.text('Góp thêm').first);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).last, '5000000');
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });
  testWidgets('move out dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const GoalDetailPage(goalId: 'home'),
      'move_out_dark',
      dark: true,
      then: (_) async {
        await t.tap(find.text('Rút ra').first);
        await t.pumpAndSettle();
        await t.enterText(find.byType(TextField).last, '5000000');
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
      },
    );
  });

  // BHomeGoal: the block only, on the page background.
  testWidgets('home block', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: GoalsHomeBlock(spacing: 0),
          ),
        ),
      ),
      'home_block',
      size: const Size(390, 300),
    );
  });
}
