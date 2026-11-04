import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/goals/domain/goal.dart';
import 'package:mobile/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:mobile/features/goals/presentation/pages/goal_editor_page.dart';
import 'package:mobile/features/goals/presentation/pages/goals_page.dart';

import 'goal_stub.dart';

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(390, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  tearDown(() => getIt.reset());

  group('MOB-P3-E01 view model', () {
    testWidgets('totals count the active goals; archived ones stay apart', (
      t,
    ) async {
      final h = await goalsApp(
        const SizedBox(),
        goals: [
          ...canvasGoals(),
          goal(id: 'old', archived: true),
        ],
      );
      await h.model.load();
      expect(h.model.active, hasLength(3));
      expect(h.model.archived, hasLength(1));
      expect(h.model.savedTotal, BigInt.from(72000000));
      expect(h.model.neededThisMonth, BigInt.from(8000000));
    });

    testWidgets('contribute replaces the goal with the server copy', (t) async {
      final h = await goalsApp(const SizedBox());
      await h.model.load();
      final home = h.model.byId('home')!;
      final saved = await h.model.contribute(
        home,
        GoalMove(
          clientId: 'c',
          amountMinor: BigInt.from(5000000),
          occurredOn: '2026-10-21',
          accountId: 'cash',
        ),
      );
      expect(saved?.currentMinor, BigInt.from(45000000));
      expect(h.model.byId('home')?.currentMinor, BigInt.from(45000000));
      expect(h.cases.moves.single.$2.accountId, 'cash');
    });
  });

  group('Mục tiêu', () {
    testWidgets('lists goals with totals and the overdue and reached tags', (
      t,
    ) async {
      tall(t);
      final h = await goalsApp(const GoalsPage());
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('Mua nhà'), findsOneWidget);
      expect(find.text('Quá hạn'), findsOneWidget);
      expect(find.text('Đã đủ'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(
        find.text('Còn 10 tháng · cần 8.000.000 mỗi tháng'),
        findsOneWidget,
      );
      expect(
        find.text('Hạn 30/09 đã qua · còn thiếu 3.000.000'),
        findsOneWidget,
      );
    });

    testWidgets('no goals: the empty state offers three kinds', (t) async {
      tall(t);
      final h = await goalsApp(const GoalsPage(), goals: const []);
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('Chưa có mục tiêu'), findsOneWidget);
      expect(find.text('Quỹ khẩn cấp'), findsOneWidget);
      expect(find.text('Du lịch'), findsOneWidget);
      expect(find.text('Mua nhà'), findsOneWidget);
    });

    testWidgets('a failed load shows a retry', (t) async {
      tall(t);
      final h = await goalsApp(const GoalsPage());
      h.cases.failure = const AuthFailure(AuthError.unavailable);
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('Không tải được mục tiêu'), findsOneWidget);
    });
  });

  group('Mục tiêu mới', () {
    testWidgets('creates the goal in the wallet it is kept in', (t) async {
      tall(t);
      final h = await goalsApp(const GoalEditorPage(initialKind: 'home'));
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      final fields = find.byType(TextField);
      await t.enterText(fields.at(1), '120000000');
      await t.pump();
      await t.tap(find.text('Tạo mục tiêu'));
      await t.pumpAndSettle();
      final draft = h.cases.created.single;
      expect(draft.kind, 'home');
      expect(draft.name, 'Mua nhà');
      expect(draft.targetMinor, BigInt.from(120000000));
      expect(draft.accountId, 'vcb');
    });

    testWidgets('a missing target blocks saving', (t) async {
      tall(t);
      final h = await goalsApp(const GoalEditorPage());
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      await t.tap(find.text('Tạo mục tiêu'));
      await t.pumpAndSettle();
      expect(find.text('Nhập số cần có.'), findsOneWidget);
      expect(h.cases.created, isEmpty);
    });
  });

  group('Chi tiết mục tiêu', () {
    testWidgets('shows progress, the month need and the history', (t) async {
      tall(t);
      final h = await goalsApp(const GoalDetailPage(goalId: 'home'));
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('33% · còn thiếu 80.000.000'), findsOneWidget);
      expect(find.text('8.000.000'), findsOneWidget);
      expect(find.text('Góp từ ví khác'), findsOneWidget);
      expect(find.text('Sửa số đã có'), findsOneWidget);
    });

    testWidgets('Góp thêm takes money from another wallet', (t) async {
      tall(t);
      final h = await goalsApp(const GoalDetailPage(goalId: 'home'));
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      await t.tap(find.text('Góp thêm').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '5000000');
      await t.pump();
      expect(find.text('Góp 5.000.000 ₫'), findsOneWidget);
      await t.tap(find.text('Góp 5.000.000 ₫'));
      await t.pumpAndSettle();
      final (kind, move) = h.cases.moves.single;
      expect(kind, 'in');
      expect(move.amountMinor, BigInt.from(5000000));
      expect(move.accountId, 'cash');
    });

    testWidgets('"Đã nằm trong" only records, no wallet is touched', (t) async {
      tall(t);
      final h = await goalsApp(const GoalDetailPage(goalId: 'home'));
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      await t.tap(find.text('Góp thêm').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '1000000');
      await t.tap(find.text('Đã nằm trong Vietcombank'));
      await t.pump();
      await t.tap(find.text('Góp 1.000.000 ₫'));
      await t.pumpAndSettle();
      expect(h.cases.moves.single.$2.accountId, isNull);
    });

    testWidgets('cannot withdraw more than the goal holds', (t) async {
      tall(t);
      final h = await goalsApp(const GoalDetailPage(goalId: 'home'));
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      await t.tap(find.text('Rút ra').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '50000000');
      await t.pump();
      expect(find.text('Vượt số đã có của mục tiêu.'), findsOneWidget);
      expect(h.cases.moves, isEmpty);
    });
  });
}
