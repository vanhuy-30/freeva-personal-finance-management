import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/net_worth_history.dart';
import '../domain/net_worth_repository.dart';

@LazySingleton(as: NetWorthRepository)
class NetWorthRepositoryImpl implements NetWorthRepository {
  NetWorthRepositoryImpl(this._api);

  final AuthorizedApi _api;

  /// Money arrives as a string; a JSON number is rejected.
  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static List<NetWorthBucket> parseHistory(Map<String, dynamic> json) =>
      List.unmodifiable(
        (json['points'] as List).map((raw) {
          final p = raw as Map<String, dynamic>;
          return (
            asOf: p['asOf'] as String,
            items: List<NetWorthRow>.unmodifiable(
              (p['items'] as List).map((item) {
                final e = item as Map<String, dynamic>;
                return (
                  currency: e['currency'] as String,
                  assetsMinor: _money(e['assetsMinor']),
                  liabilitiesMinor: _money(e['liabilitiesMinor']),
                  netWorthMinor: _money(e['netWorthMinor']),
                );
              }),
            ),
          );
        }),
      );

  static List<InvestmentBucket> parseInvestments(Map<String, dynamic> json) =>
      List.unmodifiable(
        (json['points'] as List).map((raw) {
          final p = raw as Map<String, dynamic>;
          return (
            asOf: p['asOf'] as String,
            valueByCurrency: {
              for (final item in p['items'] as List)
                (item as Map<String, dynamic>)['currency'] as String: _money(
                  item['valueMinor'],
                ),
            },
          );
        }),
      );

  Future<Either<AuthFailure, T>> _get<T>(
    String path,
    NetWorthWindow window,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final result = await _api.request(
      'GET',
      Uri(path: path, queryParameters: {'window': window.value}).toString(),
    );
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, List<NetWorthBucket>>> history(
    NetWorthWindow window,
  ) => _get('reports/net-worth/history', window, parseHistory);

  @override
  Future<Either<AuthFailure, List<InvestmentBucket>>> investmentHistory(
    NetWorthWindow window,
  ) => _get('reports/investments/history', window, parseInvestments);
}
