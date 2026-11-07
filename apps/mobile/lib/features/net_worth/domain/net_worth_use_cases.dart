import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'net_worth_history.dart';
import 'net_worth_repository.dart';

abstract class NetWorthUseCases {
  /// The default-currency row of every bucket. Buckets where the user held
  /// nothing in that currency count as zero. The investment split is best
  /// effort: when that call fails the points carry no split.
  Future<Either<AuthFailure, NetWorthSeries>> load(
    NetWorthWindow window, {
    required String currency,
  });
}

@LazySingleton(as: NetWorthUseCases)
class DefaultNetWorthUseCases implements NetWorthUseCases {
  DefaultNetWorthUseCases(this._repository);

  final NetWorthRepository _repository;

  static final _currency = RegExp(r'^[A-Z]{3}$');

  @override
  Future<Either<AuthFailure, NetWorthSeries>> load(
    NetWorthWindow window, {
    required String currency,
  }) async {
    if (!_currency.hasMatch(currency)) {
      return left(const AuthFailure(AuthError.invalidInput));
    }
    final results = await Future.wait([
      _repository.history(window),
      _repository.investmentHistory(window),
    ]);
    final history = results[0] as Either<AuthFailure, List<NetWorthBucket>>;
    final investments =
        results[1] as Either<AuthFailure, List<InvestmentBucket>>;
    return history.map((buckets) {
      final held = <String, BigInt>{
        for (final b in investments.getOrElse(() => const []))
          b.asOf: b.valueByCurrency[currency] ?? BigInt.zero,
      };
      final split = investments.isRight();
      return NetWorthSeries(
        window: window,
        currency: currency,
        points: List.unmodifiable([
          for (final b in buckets)
            _point(b, currency, split ? (held[b.asOf] ?? BigInt.zero) : null),
        ]),
      );
    });
  }

  static NetWorthPoint _point(
    NetWorthBucket bucket,
    String currency,
    BigInt? investment,
  ) {
    final row = bucket.items.where((r) => r.currency == currency).firstOrNull;
    return NetWorthPoint(
      asOf: bucket.asOf,
      assetsMinor: row?.assetsMinor ?? BigInt.zero,
      liabilitiesMinor: row?.liabilitiesMinor ?? BigInt.zero,
      netWorthMinor: row?.netWorthMinor ?? BigInt.zero,
      investmentMinor: investment,
    );
  }
}
