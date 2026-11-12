import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/spend_forecast/domain/spending_forecast.dart';
import 'package:mobile/features/spend_forecast/domain/spending_forecast_repository.dart';
import 'package:mobile/features/spend_forecast/presentation/viewmodels/spend_forecast_view_model.dart';

const b = BigInt.from;

const boardPeriod = SpendForecastPeriod(
  from: '2026-11-01',
  to: '2026-11-30',
  today: '2026-11-10',
);

/// Boards S.2 / S.3: ten days into a 30-day November, over the budget.
SpendingForecast boardForecast({
  BigInt? budget,
  bool noBudget = false,
  SpendForecastStatus status = SpendForecastStatus.ok,
}) {
  const steps = [0.3, 0.6, 1.4, 1.6, 2.2, 2.5, 3.1, 4.4, 4.9, 5.4];
  return SpendingForecast(
    status: status,
    daysElapsed: 10,
    daysInPeriod: 30,
    spentMinor: b(5400000),
    forecastMinor: status == SpendForecastStatus.ok ? b(16200000) : null,
    dailyAverageMinor: b(540000),
    budgetLimitMinor: noBudget ? null : (budget ?? b(15000000)),
    risk: noBudget ? null : SpendRisk.high,
    overBudgetMinor: noBudget ? null : b(1200000),
    dailyAllowanceMinor: noBudget ? null : b(480000),
    previousMonthMinor: b(11480000),
    cumulative: [
      for (final (i, tr) in steps.indexed)
        SpendPoint(
          date: '2026-11-${(i + 1).toString().padLeft(2, '0')}',
          spentMinor: b((tr * 1000000).round()),
        ),
    ],
    topCategories: [
      SpendTopCategory(
        id: 'food',
        name: 'Ăn uống',
        iconToken: 'food',
        colorToken: null,
        spentMinor: b(2160000),
        sharePercent: 40,
      ),
      SpendTopCategory(
        id: 'shop',
        name: 'Mua sắm',
        iconToken: 'shopping',
        colorToken: null,
        spentMinor: b(1800000),
        sharePercent: 33,
      ),
      SpendTopCategory(
        id: 'move',
        name: 'Đi lại',
        iconToken: 'transport',
        colorToken: null,
        spentMinor: b(620000),
        sharePercent: 11,
      ),
    ],
  );
}

SpendingForecastResult boardResult() => SpendingForecastResult(
  currencyCode: 'VND',
  period: boardPeriod,
  forecast: boardForecast(),
);

class FakeSpendingForecastRepository implements SpendingForecastRepository {
  SpendingForecastResult answer = SpendingForecastResult.none;
  AuthFailure? failure;
  int calls = 0;

  @override
  Future<Either<AuthFailure, SpendingForecastResult>> load() async {
    calls++;
    return failure == null ? right(answer) : left(failure!);
  }
}

/// Screen stub: a fixed forecast, load only counts.
class StubSpendForecastViewModel extends SpendForecastViewModel {
  StubSpendForecastViewModel({this.forecast, this.failure});

  @override
  final SpendingForecast? forecast;
  @override
  final AuthFailure? failure;
  @override
  String? get currencyCode => 'VND';
  @override
  SpendForecastPeriod? get period => boardPeriod;
  @override
  bool get loaded => true;
  @override
  bool get loading => false;
  int loads = 0;

  @override
  Future<void> load() async => loads++;
}
