import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'server_config.dart';

abstract class ServerConfigRepository {
  Future<Either<AuthFailure, ServerConfig>> fetch();

  /// Last copy saved on this device, or null (never loaded, or unreadable).
  Future<ServerConfig?> readCached();
  Future<void> writeCached(ServerConfig config);
  Future<void> clearCached();
}
