import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/money/money_text.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/goals/data/goal_repository_impl.dart';
import 'package:mobile/features/goals/domain/goal_forecast.dart';
import 'package:mobile/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:mobile/features/goals/presentation/viewmodels/goal_forecast_view_model.dart';
import 'package:mobile/features/goals/presentation/widgets/goal_forecast_text.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/spend_forecast/presentation/widgets/spend_forecast_labels.dart';

import '../auto_suggest/auto_suggest_fakes.dart' show FakeAuth, FakeFlags;
import 'goal_stub.dart';

GoalForecastOk ok({int? late = 6, String? target = '2027-08'}) =>
    GoalForecastOk(
      months: 3,
      averageMonthlyMinor: BigInt.from(5000000),
      expectedMonth: '2028-02',
      targetMonth: target,
      monthsLate: late,
    );

void main() {
  group('parse', () {
    test('null, reached, insufficient, ok with nulls', () {
      const parse = GoalRepositoryImpl.parseForecast;
      expect(parse({'forecast': null}), isNull);
      expect(
        parse({
          'forecast': {'status': 'reached'},
        }),
        isA<GoalForecastReached>(),
      );
      final none = parse({
        'forecast': {'status': 'insufficient', 'months': 3},
      }) as GoalForecastInsufficient;
      expect(none.months, 3);
      final f = parse({
        'forecast': {
          'status': 'ok',
          'months': 3,
          'averageMonthlyMinor': '5000000',
          'expectedMonth': '2028-02',
          'targetMonth': null,
          'monthsLate': null,
        },
      }) as GoalForecastOk;
      expect(f.averageMonthlyMinor, BigInt.from(5000000));
      expect(f.expectedMonth, '2028-02');
      expect(f.targetMonth, isNull);
      expect(f.monthsLate, isNull);
    });
  });

  group('text (vi)', () {
    final s = lookupS(const Locale('vi'));
    String money(BigInt v) => formatMoneyText(v, 0, 'vi');

    test('chip: late, early, on time, no date', () {
      expect(goalForecastChip(s, ok()), ('Trễ 6 tháng', ForecastTone.warning));
      expect(goalForecastChip(s, ok(late: -2)), (
        'Sớm 2 tháng',
        ForecastTone.success,
      ));
      expect(goalForecastChip(s, ok(late: 0)), (
        'Kịp hạn',
        ForecastTone.success,
      ));
      expect(goalForecastChip(s, ok(late: null, target: null)), isNull);
    });

    test('line adds the catch-up only when late', () {
      final g = goal(perMonth: 8000000);
      expect(
        goalForecastLine(s, ok(), g, money),
        'Góp trung bình 5.000.000 mỗi tháng trong 3 tháng qua. '
        'Góp 8.000.000 mỗi tháng để kịp hạn.',
      );
      expect(
        goalForecastLine(s, ok(late: -1), g, money),
        'Góp trung bình 5.000.000 mỗi tháng trong 3 tháng qua.',
      );
      expect(
        goalForecastLine(s, ok(), goal(), money),
        'Góp trung bình 5.000.000 mỗi tháng trong 3 tháng qua.',
      );
    });

    test('timeline: late, early, on time', () {
      final late = goalTimeline(
        today: '2026-11-12',
        target: '2027-08',
        expected: '2028-02',
      );
      expect(late.marks.map((m) => m.kind), [
        GoalMarkKind.today,
        GoalMarkKind.due,
        GoalMarkKind.expected,
      ]);
      expect(late.marks[1].at, closeTo(0.6, 1e-9));
      expect(late.marks.map((m) => m.month), ['11/2026', '08/2027', '02/2028']);
      expect(late.late, isTrue);
      final early = goalTimeline(
        today: '2026-11-12',
        target: '2028-02',
        expected: '2027-08',
      );
      expect(early.marks[1].kind, GoalMarkKind.expected);
      expect(early.marks.last.kind, GoalMarkKind.due);
      expect(early.late, isFalse);
      final onTime = goalTimeline(
        today: '2026-11-12',
        target: '2027-08',
        expected: '2027-08',
      );
      expect(onTime.marks, hasLength(2));
      expect(onTime.solid, 1);
    });
  });

  group('view model', () {
    late FakeGoalUseCases cases;
    late FakeFlags flags;
    late FakeAuth auth;
    late GoalForecastViewModel model;

    setUp(() {
      cases = FakeGoalUseCases()..forecastResult = ok();
      flags = FakeFlags()..on = {FeatureFlags.forecast};
      auth = FakeAuth();
      model = GoalForecastViewModel(cases, flags, auth);
    });

    test('flag off: no call', () async {
      flags.on = {};
      await model.load('home');
      expect(cases.forecastCalls, isEmpty);
      expect(model.shown, isNull);
    });

    test('ok and insufficient are shown; reached is not', () async {
      await model.load('home');
      expect(model.shown, isA<GoalForecastOk>());
      cases.forecastResult = const GoalForecastInsufficient(months: 3);
      await model.load('home');
      expect(model.shown, isA<GoalForecastInsufficient>());
      cases.forecastResult = const GoalForecastReached();
      await model.load('home');
      expect(model.shown, isNull);
    });

    test('error hides the card', () async {
      await model.load('home');
      cases.forecastFailure = const AuthFailure(AuthError.expired);
      await model.load('home');
      expect(model.shown, isNull);
      expect(auth.expired, 1);
    });
  });

  group('Chi tiết mục tiêu', () {
    tearDown(() => getIt.reset());

    void tall(WidgetTester t) {
      t.view.physicalSize = const Size(390, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
    }

    testWidgets('shows the forecast card and the Hạn tile', (t) async {
      tall(t);
      final h = await goalsApp(
        const GoalDetailPage(goalId: 'home'),
        forecast: ok(),
      );
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('Hạn'), findsWidgets);
      expect(find.text('Ngày đạt'), findsNothing);
      expect(find.text('Dự kiến đạt 02/2028'), findsOneWidget);
      expect(find.text('Trễ 6 tháng'), findsOneWidget);
      expect(h.cases.forecastCalls, ['home']);
    });

    testWidgets('no contribution yet', (t) async {
      tall(t);
      final h = await goalsApp(
        const GoalDetailPage(goalId: 'home'),
        forecast: const GoalForecastInsufficient(months: 3),
      );
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      expect(find.text('Chưa đủ dữ liệu để dự kiến'), findsOneWidget);
      expect(find.text('Góp lần đầu để xem ngày đạt.'), findsOneWidget);
    });

    testWidgets('reloads after a contribution', (t) async {
      tall(t);
      final h = await goalsApp(
        const GoalDetailPage(goalId: 'home'),
        forecast: ok(),
      );
      await t.pumpWidget(h.app);
      await t.pumpAndSettle();
      await t.tap(find.text('Góp thêm').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '5000000');
      await t.pump();
      await t.tap(find.text('Góp 5.000.000 ₫'));
      await t.pumpAndSettle();
      expect(h.cases.forecastCalls, ['home', 'home']);
    });
  });
}
