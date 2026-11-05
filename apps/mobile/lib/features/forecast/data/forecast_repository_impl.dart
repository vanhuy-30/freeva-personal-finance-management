import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/balance_forecast.dart';
import '../domain/forecast_repository.dart';

@LazySingleton(as: ForecastRepository)
class ForecastRepositoryImpl implements ForecastRepository {
  ForecastRepositoryImpl(this._api);

  final AuthorizedApi _api;

  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static List<String> _ids(Object? value) =>
      List.unmodifiable((value as List).cast<String>());

  static BalanceForecast parse(Map<String, dynamic> json) {
    final assumptions = json['assumptions'] as Map<String, dynamic>;
    return BalanceForecast(
      currencyCode: json['currencyCode'] as String,
      from: json['from'] as String,
      to: json['to'] as String,
      startingBalanceMinor: _money(json['startingBalanceMinor']),
      months: List.unmodifiable(
        (json['months'] as List).map((raw) {
          final e = raw as Map<String, dynamic>;
          return ForecastMonth(
            month: e['month'] as String,
            openingMinor: _money(e['openingMinor']),
            incomeMinor: _money(e['incomeMinor']),
            expenseMinor: _money(e['expenseMinor']),
            closingMinor: _money(e['closingMinor']),
          );
        }),
      ),
      assumptions: ForecastAssumptions(
        fromWallets: assumptions['balanceSource'] == 'wallets',
        includedRuleIds: _ids(assumptions['includedRuleIds']),
        excludedRuleIds: _ids(assumptions['excludedRuleIds']),
        otherCurrencyRuleIds: _ids(assumptions['otherCurrencyRuleIds']),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, BalanceForecast>> forecast({
    required int months,
    String? currencyCode,
    BigInt? startingBalanceMinor,
    List<String> excludeRuleIds = const [],
  }) async {
    final result = await _api.request(
      'GET',
      Uri(
        path: 'forecast',
        queryParameters: {
          'months': '$months',
          if (currencyCode != null) 'currencyCode': currencyCode,
          if (startingBalanceMinor != null)
            'startingBalanceMinor': startingBalanceMinor.toString(),
          if (excludeRuleIds.isNotEmpty)
            'excludeRuleIds': excludeRuleIds.join(','),
        },
      ).toString(),
    );
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }
}
