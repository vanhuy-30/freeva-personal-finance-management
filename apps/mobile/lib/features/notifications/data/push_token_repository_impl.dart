import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/push_registrar.dart';

@LazySingleton(as: PushTokenRepository)
class PushTokenRepositoryImpl implements PushTokenRepository {
  PushTokenRepositoryImpl(this._api);

  final AuthorizedApi _api;

  @override
  Future<Either<AuthFailure, Unit>> put(String token, String platform) async {
    final result = await _api.request(
      'PUT',
      'push-tokens',
      body: {'token': token, 'platform': platform},
    );
    return result.map((_) => unit);
  }

  @override
  Future<Either<AuthFailure, Unit>> remove() async {
    final result = await _api.request('DELETE', 'push-tokens');
    return result.map((_) => unit);
  }
}
