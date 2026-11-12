import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/money/money_text.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/insights/presentation/pages/insights_page.dart';
import 'package:mobile/features/insights/presentation/viewmodels/insights_view_model.dart';
import 'package:mobile/features/server_config/domain/server_config.dart';
import 'package:mobile/features/spend_forecast/data/spending_forecast_repository_impl.dart';
import 'package:mobile/features/spend_forecast/domain/spending_forecast.dart';
import 'package:mobile/features/spend_forecast/presentation/pages/spend_forecast_page.dart';
import 'package:mobile/features/spend_forecast/presentation/viewmodels/spend_forecast_view_model.dart';
import 'package:mobile/features/spend_forecast/presentation/widgets/spend_forecast_labels.dart';

import '../auto_suggest/auto_suggest_fakes.dart' show FakeAuth, FakeFlags;
import '../insights/insights_fakes.dart';
import 'spend_forecast_fakes.dart';

Widget _app(Widget home) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('vi'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: home,
);

void _tall(WidgetTester t) {
  t.view.physicalSize = const Size(390, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  group('parse', () {
    test('ok with every field', () {
      final r = SpendingForecastRepositoryImpl.parse({
        'currencyCode': 'VND',
        'period': {
          'from': '2026-11-01',
          'to': '2026-11-30',
          'today': '2026-11-10',
        },
        'forecast': {
          'status': 'ok',
          'daysElapsed': 10,
          'daysInPeriod': 30,
          'spentMinor': '5400000',
          'forecastMinor': '16200000',
          'dailyAverageMinor': '540000',
          'budgetLimitMinor': '15000000',
          'risk': 'high',
          'overBudgetMinor': '1200000',
          'dailyAllowanceMinor': '480000',
          'previousMonthMinor': '11480000',
          'cumulative': [
            {'date': '2026-11-01', 'spentMinor': '300000'},
          ],
          'topCategories': [
            {
              'category': {
                'id': 'c1',
                'name': 'Ăn uống',
                'iconToken': 'food',
                'colorToken': null,
              },
              'spentMinor': '2160000',
              'sharePercent': 40,
            },
          ],
        },
      });
      final f = r.forecast!;
      expect(r.currencyCode, 'VND');
      expect(r.period?.today, '2026-11-10');
      expect(f.ready, isTrue);
      expect(f.forecastMinor, BigInt.from(16200000));
      expect(f.risk, SpendRisk.high);
      expect(f.dailyAllowanceMinor, BigInt.from(480000));
      expect(f.cumulative.single.spentMinor, BigInt.from(300000));
      expect(f.topCategories.single.name, 'Ăn uống');
      expect(f.topCategories.single.sharePercent, 40);
    });

    test('insufficient with nulls inside', () {
      final f = SpendingForecastRepositoryImpl.parse({
        'currencyCode': 'VND',
        'period': null,
        'forecast': {
          'status': 'insufficient',
          'daysElapsed': 2,
          'daysInPeriod': 30,
          'spentMinor': '100',
          'forecastMinor': null,
          'dailyAverageMinor': '50',
          'budgetLimitMinor': null,
          'risk': null,
          'overBudgetMinor': null,
          'dailyAllowanceMinor': null,
          'previousMonthMinor': '0',
          'cumulative': [],
          'topCategories': [],
        },
      }).forecast!;
      expect(f.status, SpendForecastStatus.insufficient);
      expect(f.ready, isFalse);
      expect(f.forecastMinor, isNull);
      expect(f.risk, isNull);
      expect(f.budgetLimitMinor, isNull);
    });

    test('forecast null when off', () {
      final r = SpendingForecastRepositoryImpl.parse({
        'currencyCode': null,
        'period': null,
        'forecast': null,
      });
      expect(r.forecast, isNull);
    });
  });

  group('view model', () {
    late FakeSpendingForecastRepository repo;
    late FakeFlags flags;
    late FakeAuth auth;
    late DefaultSpendForecastViewModel model;

    setUp(() {
      repo = FakeSpendingForecastRepository()..answer = boardResult();
      flags = FakeFlags()..on = {FeatureFlags.forecast};
      auth = FakeAuth();
      model = DefaultSpendForecastViewModel(repo, flags, auth);
    });

    test('flag off: no call, nothing shown', () async {
      flags.on = {};
      await model.load();
      expect(repo.calls, 0);
      expect(model.forecast, isNull);
      expect(model.loaded, isTrue);
    });

    test('loads the forecast', () async {
      await model.load();
      expect(repo.calls, 1);
      expect(model.forecast?.forecastMinor, BigInt.from(16200000));
      expect(model.currencyCode, 'VND');
    });

    test('error hides it; expired session is reported', () async {
      await model.load();
      repo.failure = const AuthFailure(AuthError.expired);
      await model.load();
      expect(model.forecast, isNull);
      expect(model.failure?.code, AuthError.expired);
      expect(auth.expired, 1);
    });
  });

  group('labels (vi)', () {
    final s = lookupS(const Locale('vi'));
    String money(BigInt v) => formatMoneyText(v, 0, 'vi');

    test('risk chip per level, none without a budget', () {
      expect(riskChip(s, SpendRisk.low), ('Rủi ro thấp', ForecastTone.success));
      expect(riskChip(s, SpendRisk.medium), (
        'Rủi ro vừa',
        ForecastTone.warning,
      ));
      expect(riskChip(s, SpendRisk.high), ('Rủi ro cao', ForecastTone.danger));
      expect(riskChip(s, null), isNull);
    });

    test('allowance tile, else last month', () {
      expect(forecastSideTile(s, boardForecast(), money), (
        'Để không vượt, mỗi ngày',
        'dưới 480.000',
        ForecastTone.success,
      ));
      expect(forecastSideTile(s, boardForecast(noBudget: true), money), (
        'Tháng trước',
        '11.480.000',
        ForecastTone.neutral,
      ));
    });

    test('legend compares with the budget, else last month', () {
      expect(
        forecastCompare(s, boardForecast(), money),
        'Ngân sách 15.000.000',
      );
      expect(
        forecastCompare(s, boardForecast(noBudget: true), money),
        'Tháng trước 11.480.000',
      );
    });

    test('chart is read out with or without a budget', () {
      expect(
        forecastChartLabel(s, boardForecast(), money),
        'Đã chi 5.400.000 sau 10 ngày, dự báo 16.200.000 cuối tháng, '
        'ngân sách 15.000.000',
      );
      expect(
        forecastChartLabel(s, boardForecast(noBudget: true), money),
        'Đã chi 5.400.000 sau 10 ngày, dự báo 16.200.000 cuối tháng',
      );
    });
  });

  group('Phân tích', () {
    tearDown(() => getIt.reset());

    testWidgets('shows the card even with no insights', (t) async {
      _tall(t);
      final forecast = StubSpendForecastViewModel(forecast: boardForecast());
      getIt
        ..registerSingleton<InsightsViewModel>(
          StubInsightsViewModel(items: const []),
        )
        ..registerSingleton<SpendForecastViewModel>(forecast);
      await t.pumpWidget(_app(const InsightsPage()));
      await t.pump();
      expect(find.text('Dự báo chi cuối tháng 11'), findsOneWidget);
      expect(find.text('16.200.000'), findsOneWidget);
      expect(find.text('Rủi ro cao'), findsOneWidget);
      expect(find.text('Chưa có điều gì đáng chú ý'), findsOneWidget);
      expect(forecast.loads, 1);
    });

    testWidgets('no card when off or failed', (t) async {
      _tall(t);
      getIt
        ..registerSingleton<InsightsViewModel>(StubInsightsViewModel())
        ..registerSingleton<SpendForecastViewModel>(
          StubSpendForecastViewModel(
            failure: const AuthFailure(AuthError.network),
          ),
        );
      await t.pumpWidget(_app(const InsightsPage()));
      await t.pump();
      expect(find.textContaining('Dự báo chi'), findsNothing);
      expect(find.text('ĐÁNG CHÚ Ý · 4'), findsOneWidget);
    });

    testWidgets('too early: says so instead of a number', (t) async {
      _tall(t);
      getIt
        ..registerSingleton<InsightsViewModel>(StubInsightsViewModel())
        ..registerSingleton<SpendForecastViewModel>(
          StubSpendForecastViewModel(
            forecast: boardForecast(status: SpendForecastStatus.insufficient),
          ),
        );
      await t.pumpWidget(_app(const InsightsPage()));
      await t.pump();
      expect(
        find.text('Chưa đủ dữ liệu, xem lại sau vài ngày'),
        findsOneWidget,
      );
      expect(find.text('Rủi ro cao'), findsNothing);
    });
  });

  group('Dự báo chi', () {
    tearDown(() => getIt.reset());

    testWidgets('board figures', (t) async {
      _tall(t);
      getIt.registerSingleton<SpendForecastViewModel>(
        StubSpendForecastViewModel(forecast: boardForecast()),
      );
      await t.pumpWidget(_app(const SpendForecastPage()));
      await t.pump();
      expect(find.text('Cuối tháng 11 có thể chi khoảng'), findsOneWidget);
      expect(find.text('Vượt ngân sách khoảng 1.200.000'), findsOneWidget);
      expect(find.text('Ngân sách 15tr'), findsOneWidget);
      expect(find.text('dưới 480.000'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
    });

    testWidgets('too early: empty state', (t) async {
      _tall(t);
      getIt.registerSingleton<SpendForecastViewModel>(
        StubSpendForecastViewModel(
          forecast: boardForecast(status: SpendForecastStatus.insufficient),
        ),
      );
      await t.pumpWidget(_app(const SpendForecastPage()));
      await t.pump();
      expect(find.text('Chưa đủ dữ liệu'), findsOneWidget);
      expect(find.text('Xem lại sau vài ngày.'), findsOneWidget);
    });
  });
}
