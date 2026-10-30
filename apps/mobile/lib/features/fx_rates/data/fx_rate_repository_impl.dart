import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/money/display_converted.dart';
import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/fx_rate.dart';
import '../domain/fx_rate_repository.dart';

@LazySingleton(as: FxRateRepository)
class FxRateRepositoryImpl implements FxRateRepository {
  FxRateRepositoryImpl(this._api);

  final AuthorizedApi _api;

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _api.request(method, path, body: body);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, List<FxRate>>> list() => _request(
    'GET',
    'fx-rates',
    (json) => [
      for (final row in json['items'] as List)
        _rate(row as Map<String, dynamic>),
    ],
  );

  @override
  Future<Either<AuthFailure, FxRate>> put(
    String from,
    String to,
    String rate,
  ) => _request('PUT', 'fx-rates/$from/$to', _rate, body: {'rate': rate});

  @override
  Future<Either<AuthFailure, DisplayConverted?>> walletConverted(String id) =>
      _request(
        'GET',
        'financial-accounts/$id',
        (json) => DisplayConverted.fromJson(json['converted']),
      );

  @override
  Future<Either<AuthFailure, DisplayConverted?>> transactionConverted(
    String legId,
  ) => _request('GET', 'transactions/$legId', (json) {
    for (final leg in json['legs'] as List) {
      final row = leg as Map<String, dynamic>;
      if (row['id'] == legId) return DisplayConverted.fromJson(row['converted']);
    }
    return null;
  });

  @override
  Future<Either<AuthFailure, Unit>> remove(String from, String to) =>
      _request('DELETE', 'fx-rates/$from/$to', (_) => unit);
}

FxRate _rate(Map<String, dynamic> json) {
  final from = json['fromCode'] as String;
  final to = json['toCode'] as String;
  final rate = json['rate'] as String;
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(from) ||
      !RegExp(r'^[A-Z]{3}$').hasMatch(to) ||
      !RegExp(r'^\d+(\.\d+)?$').hasMatch(rate)) {
    throw const FormatException();
  }
  return FxRate(
    from: from,
    to: to,
    rate: rate,
    quotedAt: DateTime.parse(json['quotedAt'] as String),
  );
}
