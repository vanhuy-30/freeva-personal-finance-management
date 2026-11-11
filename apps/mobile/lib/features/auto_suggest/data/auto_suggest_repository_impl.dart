import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/auto_suggest_repository.dart';
import '../domain/merchant_mapping.dart';

@LazySingleton(as: AutoSuggestRepository)
class AutoSuggestRepositoryImpl implements AutoSuggestRepository {
  AutoSuggestRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static const _mappings = 'category-suggestions/mappings';

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

  MerchantMapping _mapping(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>;
    return MerchantMapping(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      categoryId: category['id'] as String,
      categoryName: category['name'] as String,
      iconToken: category['iconToken'] as String?,
      colorToken: category['colorToken'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> setEnabled(bool enabled) => _request(
    'PUT',
    'profile/auto-suggest',
    (_) => unit,
    body: {'enabled': enabled},
  );

  @override
  Future<Either<AuthFailure, List<MerchantMapping>>> mappings() => _request(
    'GET',
    _mappings,
    (json) => List.unmodifiable([
      for (final item in json['items'] as List)
        _mapping(item as Map<String, dynamic>),
    ]),
  );

  @override
  Future<Either<AuthFailure, Unit>> forget(String id) =>
      _request('DELETE', '$_mappings/${Uri.encodeComponent(id)}', (_) => unit);

  @override
  Future<Either<AuthFailure, Unit>> clear() =>
      _request('DELETE', _mappings, (_) => unit);
}
