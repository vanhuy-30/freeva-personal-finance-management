import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'server_config.dart';

abstract class ServerConfigRepository {
  /// Signed in: flags for this user plus config.
  Future<Either<AuthFailure, ServerConfig>> fetch();

  /// No session (sign-up, reset…): config only, no flags (`/app-config/public`).
  Future<Either<AuthFailure, ServerConfig>> fetchPublic();

  /// Last copy saved on this device, or null (never loaded, or unreadable).
  Future<ServerConfig?> readCached();
  Future<void> writeCached(ServerConfig config);
  Future<void> clearCached();
}
