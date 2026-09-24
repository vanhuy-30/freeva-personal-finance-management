import 'package:dartz/dartz.dart';

import '../domain/auth_repository.dart';

abstract class AuthorizedApi {
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  });
}
