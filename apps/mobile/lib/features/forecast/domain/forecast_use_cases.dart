import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'balance_forecast.dart';
import 'forecast_repository.dart';
import '../../server_config/domain/app_limits.dart';

abstract class ForecastUseCases {
  /// [months] counts the current month (1–12). Rejects other values and
  /// malformed currency codes before calling the API.
  Future<Either<AuthFailure, BalanceForecast>> load({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    Set<String> excludeRuleIds = const {},
  });
}

@LazySingleton(as: ForecastUseCases)
class DefaultForecastUseCases implements ForecastUseCases {
  DefaultForecastUseCases(this._repository, this._limits);

  final AppLimitsSource _limits;

  final ForecastRepository _repository;

  static final _currency = RegExp(r'^[A-Z]{3}$');

  @override
  Future<Either<AuthFailure, BalanceForecast>> load({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    Set<String> excludeRuleIds = const {},
  }) {
    if (months < 1 ||
        months > _limits.requireLimits.forecastMaxMonths ||
        (currencyCode != null && !_currency.hasMatch(currencyCode))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.forecast(
      months: months,
      currencyCode: currencyCode,
      startingBalanceMinor: startingBalanceMinor,
      excludeRuleIds: excludeRuleIds.toList()..sort(),
    );
  }
}
