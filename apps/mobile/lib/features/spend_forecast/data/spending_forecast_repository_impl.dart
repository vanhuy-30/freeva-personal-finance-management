import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/spending_forecast.dart';
import '../domain/spending_forecast_repository.dart';

@LazySingleton(as: SpendingForecastRepository)
class SpendingForecastRepositoryImpl implements SpendingForecastRepository {
  SpendingForecastRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, SpendingForecastResult>> load() async {
    final result = await _api.request('GET', 'spending-forecast');
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  /// Parses the response; money stays in minor units as [BigInt].
  static SpendingForecastResult parse(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>?;
    final forecast = json['forecast'] as Map<String, dynamic>?;
    return SpendingForecastResult(
      currencyCode: json['currencyCode'] as String?,
      period: period == null
          ? null
          : SpendForecastPeriod(
              from: period['from'] as String,
              to: period['to'] as String,
              today: period['today'] as String,
            ),
      forecast: forecast == null ? null : _forecast(forecast),
    );
  }

  static SpendingForecast _forecast(Map<String, dynamic> json) =>
      SpendingForecast(
        status: switch (json['status']) {
          'ok' => SpendForecastStatus.ok,
          'insufficient' => SpendForecastStatus.insufficient,
          final other => throw FormatException('status $other'),
        },
        daysElapsed: (json['daysElapsed'] as num).toInt(),
        daysInPeriod: (json['daysInPeriod'] as num).toInt(),
        spentMinor: _money(json['spentMinor']),
        forecastMinor: _maybe(json['forecastMinor']),
        dailyAverageMinor: _money(json['dailyAverageMinor']),
        budgetLimitMinor: _maybe(json['budgetLimitMinor']),
        risk: switch (json['risk']) {
          'low' => SpendRisk.low,
          'medium' => SpendRisk.medium,
          'high' => SpendRisk.high,
          _ => null,
        },
        overBudgetMinor: _maybe(json['overBudgetMinor']),
        dailyAllowanceMinor: _maybe(json['dailyAllowanceMinor']),
        previousMonthMinor: _money(json['previousMonthMinor']),
        cumulative: List.unmodifiable([
          for (final raw in json['cumulative'] as List? ?? const [])
            SpendPoint(
              date: (raw as Map<String, dynamic>)['date'] as String,
              spentMinor: _money(raw['spentMinor']),
            ),
        ]),
        topCategories: List.unmodifiable([
          for (final raw in json['topCategories'] as List? ?? const [])
            _top(raw as Map<String, dynamic>),
        ]),
      );

  static SpendTopCategory _top(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>;
    return SpendTopCategory(
      id: category['id'] as String,
      name: category['name'] as String,
      iconToken: category['iconToken'] as String?,
      colorToken: category['colorToken'] as String?,
      spentMinor: _money(json['spentMinor']),
      sharePercent: (json['sharePercent'] as num).toInt(),
    );
  }

  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static BigInt? _maybe(Object? value) =>
      value == null ? null : BigInt.parse(value as String);
}
