import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'balance_forecast.dart';

abstract class ForecastRepository {
  Future<Either<AuthFailure, BalanceForecast>> forecast({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    List<String> excludeRuleIds = const [],
  });
}
