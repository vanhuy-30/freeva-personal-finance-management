import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/money/money_text.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/insights/data/insights_repository_impl.dart';
import 'package:mobile/features/insights/domain/insight.dart';
import 'package:mobile/features/insights/presentation/viewmodels/insights_view_model.dart';
import 'package:mobile/features/insights/presentation/widgets/insight_text.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';

import '../auto_suggest/auto_suggest_fakes.dart' show FakeAuth, FakeFlags;
import '../home/home_test_app.dart';
import 'insights_fakes.dart';

Map<String, dynamic> _cat(String id, String name) => {
  'id': id,
  'name': name,
  'iconToken': null,
  'colorToken': null,
};

void main() {
  group('parse', () {
    test('reads every kind with money as BigInt', () {
      final list = InsightsRepositoryImpl.parse({
        'currencyCode': 'VND',
        'period': {
          'from': '2026-11-01',
          'to': '2026-11-30',
          'today': '2026-11-10',
        },
        'items': [
          {
            'kind': 'budget_risk',
            'category': null,
            'spentMinor': '9000000000000000001',
            'limitMinor': '10000000000000000000',
            'percent': 90,
            'daysLeft': 20,
          },
          {
            'kind': 'outlier',
            'category': _cat('c1', 'Mua sắm'),
            'transactionId': 't1',
            'merchant': null,
            'occurredOn': '2026-11-08',
            'amountMinor': '1250000',
            'usualMinor': '420000',
            'times': 2,
          },
          {
            'kind': 'category_change',
            'category': _cat('c2', 'Ăn uống'),
            'currentMinor': '2160000',
            'previousMinor': '1600000',
            'changePercent': null,
            'direction': 'down',
          },
          {
            'kind': 'spend_trend',
            'currentMinor': '5400000',
            'previousMinor': '4580000',
            'changePercent': 18,
            'direction': 'up',
            'days': 10,
          },
        ],
      });
      expect(list.currencyCode, 'VND');
      expect(list.period?.today, '2026-11-10');
      final [budget, outlier, change, trend] = list.items;
      budget as BudgetRiskInsight;
      expect(budget.category, isNull);
      expect(budget.spentMinor, BigInt.parse('9000000000000000001'));
      expect(budget.percent, 90);
      expect(budget.daysLeft, 20);
      outlier as OutlierInsight;
      expect(outlier.merchant, isNull);
      expect(outlier.category.name, 'Mua sắm');
      expect(outlier.usualMinor, BigInt.from(420000));
      expect(outlier.transactionId, 't1');
      change as CategoryChangeInsight;
      expect(change.changePercent, isNull);
      expect(change.up, isFalse);
      trend as SpendTrendInsight;
      expect(trend.changePercent, 18);
      expect(trend.up, isTrue);
      expect(trend.days, 10);
    });

    test('skips kinds this app does not know; empty period', () {
      final list = InsightsRepositoryImpl.parse({
        'currencyCode': null,
        'period': null,
        'items': [
          {'kind': 'forecast_risk', 'whatever': 1},
          {
            'kind': 'spend_trend',
            'currentMinor': '1',
            'previousMinor': '2',
            'changePercent': null,
            'direction': 'down',
            'days': 1,
          },
        ],
      });
      expect(list.period, isNull);
      expect(list.currencyCode, isNull);
      expect(list.items.single, isA<SpendTrendInsight>());
    });
  });

  group('view model', () {
    late FakeInsightsRepository repo;
    late FakeFlags flags;
    late FakeAuth auth;
    late DefaultInsightsViewModel model;

    setUp(() {
      repo = FakeInsightsRepository()..answer = boardList();
      flags = FakeFlags()..on = {FeatureFlags.insights};
      auth = FakeAuth();
      model = DefaultInsightsViewModel(repo, flags, auth);
    });

    test('flag off: no call, nothing shown', () async {
      flags.on = {};
      await model.load();
      expect(repo.calls, 0);
      expect(model.first, isNull);
      expect(model.loaded, isTrue);
    });

    test('Overview gets the first item; count is the list', () async {
      await model.load();
      expect(repo.calls, 1);
      expect(model.first, isA<CategoryChangeInsight>());
      expect(model.items, hasLength(4));
      expect(model.currencyCode, 'VND');
    });

    test('error hides the card; expired session is reported', () async {
      await model.load();
      repo.failure = const AuthFailure(AuthError.expired);
      await model.load();
      expect(model.first, isNull);
      expect(model.failure?.code, AuthError.expired);
      expect(auth.expired, 1);
    });

    test('signing out clears the items', () async {
      await model.load();
      auth
        ..stage = AuthStage.signedOut
        ..notifyListeners();
      expect(model.items, isEmpty);
      expect(model.loaded, isFalse);
    });
  });

  group('sentence (vi)', () {
    final s = lookupS(const Locale('vi'));
    String money(BigInt v) => formatMoneyText(v, 0, 'vi');
    String say(Insight item) => insightTitle(s, item, money);
    const b = BigInt.from;

    test('budget: category and whole month', () {
      BudgetRiskInsight budget(InsightCategory? c) => BudgetRiskInsight(
        category: c,
        spentMinor: b(1800000),
        limitMinor: b(2000000),
        percent: 90,
        daysLeft: 20,
      );
      expect(say(budget(shopping)), 'Mua sắm đã dùng 90% ngân sách');
      expect(say(budget(null)), 'Chi tháng này đã dùng 90% ngân sách');
    });

    test('outlier: merchant, else category', () {
      OutlierInsight outlier(String? merchant) => OutlierInsight(
        category: shopping,
        transactionId: 't',
        merchant: merchant,
        occurredOn: '2026-11-08',
        amountMinor: b(1250000),
        usualMinor: b(420000),
        times: 3,
      );
      expect(
        say(outlier('Điện máy Xanh')),
        'Khoản 1.250.000 ở Điện máy Xanh cao gấp 3 lần mức thường',
      );
      expect(
        say(outlier(null)),
        'Khoản 1.250.000 ở Mua sắm cao gấp 3 lần mức thường',
      );
    });

    test('category change: up, down, without a percent', () {
      CategoryChangeInsight change(bool up, int? p) => CategoryChangeInsight(
        category: food,
        currentMinor: b(2160000),
        previousMinor: b(1600000),
        changePercent: p,
        up: up,
      );
      expect(
        say(change(true, 35)),
        'Ăn uống tăng 35% so với cùng kỳ tháng trước',
      );
      expect(
        say(change(false, 20)),
        'Ăn uống giảm 20% so với cùng kỳ tháng trước',
      );
      expect(
        say(change(true, null)),
        'Ăn uống tháng này nhiều hơn tháng trước',
      );
      expect(say(change(false, null)), 'Ăn uống tháng này ít hơn tháng trước');
    });

    test('spend trend: up, down, without a percent', () {
      SpendTrendInsight trend(bool up, int? p) => SpendTrendInsight(
        currentMinor: b(5400000),
        previousMinor: b(4580000),
        changePercent: p,
        up: up,
        days: 10,
      );
      expect(
        say(trend(true, 18)),
        'Chi 10 ngày đầu tháng nhiều hơn tháng trước 18%',
      );
      expect(
        say(trend(false, 18)),
        'Chi 10 ngày đầu tháng ít hơn tháng trước 18%',
      );
      expect(say(trend(true, null)), 'Chi tháng này nhiều hơn tháng trước');
      expect(say(trend(false, null)), 'Chi tháng này ít hơn tháng trước');
    });

    test('see-all link and days left', () {
      expect(s.insightsSeeAll(4), 'Xem cả 4');
      expect(s.insightsSeeAll(1), 'Xem phân tích');
      expect(s.insightDaysLeft(20), 'còn 20 ngày');
    });
  });

  group('Overview card', () {
    tearDown(() => getIt.reset());

    testWidgets('shows the first insight and the count', (t) async {
      t.view.physicalSize = const Size(390, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final app = await homeApp(homeState('ready'));
      final insights = StubInsightsViewModel();
      getIt.registerSingleton<InsightsViewModel>(insights);
      await t.pumpWidget(app);
      await t.pump();
      expect(
        find.text('Ăn uống tăng 35% so với cùng kỳ tháng trước'),
        findsOneWidget,
      );
      expect(find.text('Xem cả 4'), findsOneWidget);
      expect(find.text('Mua sắm đã dùng 90% ngân sách'), findsNothing);
      expect(insights.loads, 1);
    });

    testWidgets('hidden with nothing to say', (t) async {
      t.view.physicalSize = const Size(390, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final app = await homeApp(homeState('ready'));
      getIt.registerSingleton<InsightsViewModel>(
        StubInsightsViewModel(items: const []),
      );
      await t.pumpWidget(app);
      await t.pump();
      expect(find.text('Đáng chú ý'), findsNothing);
    });
  });
}
