import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import '../../net_worth/domain/net_worth_history.dart';
import 'investment.dart';
import 'investment_repository.dart';

abstract class InvestmentUseCases {
  Future<Either<AuthFailure, List<Investment>>> list();

  Future<Either<AuthFailure, InvestmentSummary>> summary();

  /// Value line of [currency] over [window]; buckets without that currency
  /// count as zero.
  Future<Either<AuthFailure, List<InvestmentValuePoint>>> valueLine(
    NetWorthWindow window, {
    required String currency,
  });
}

@LazySingleton(as: InvestmentUseCases)
class DefaultInvestmentUseCases implements InvestmentUseCases {
  DefaultInvestmentUseCases(this._repository);

  final InvestmentRepository _repository;

  static final _currency = RegExp(r'^[A-Z]{3}$');

  @override
  Future<Either<AuthFailure, List<Investment>>> list() => _repository.list();

  @override
  Future<Either<AuthFailure, InvestmentSummary>> summary() =>
      _repository.summary();

  @override
  Future<Either<AuthFailure, List<InvestmentValuePoint>>> valueLine(
    NetWorthWindow window, {
    required String currency,
  }) async {
    if (!_currency.hasMatch(currency)) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    final result = await _repository.history(window);
    return result.map(
      (buckets) => List.unmodifiable([
        for (final b in buckets)
          InvestmentValuePoint(
            asOf: b.asOf,
            valueMinor: b.valueByCurrency[currency] ?? BigInt.zero,
          ),
      ]),
    );
  }
}
