import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/server_config.dart';
import '../domain/server_config_repository.dart';
import 'server_config_vault.dart';

@LazySingleton(as: ServerConfigRepository)
class ServerConfigRepositoryImpl implements ServerConfigRepository {
  ServerConfigRepositoryImpl(this._api, this._vault);

  final AuthorizedApi _api;
  final ServerConfigVault _vault;

  @override
  Future<Either<AuthFailure, ServerConfig>> fetch() async {
    final result = await _api.request('GET', 'app-config');
    return result.fold(left, (json) {
      try {
        return right(ServerConfig.fromJson(json));
      } on FormatException {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<ServerConfig?> readCached() async {
    try {
      final raw = await _vault.read();
      if (raw == null) return null;
      return ServerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // A broken copy is the same as no copy: the next fetch replaces it.
      return null;
    }
  }

  @override
  Future<void> writeCached(ServerConfig config) =>
      _vault.write(jsonEncode(config.toJson()));

  @override
  Future<void> clearCached() => _vault.delete();
}
