import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/auth_api.dart';
import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/server_config.dart';
import '../domain/server_config_repository.dart';
import 'server_config_vault.dart';

@LazySingleton(as: ServerConfigRepository)
class ServerConfigRepositoryImpl implements ServerConfigRepository {
  ServerConfigRepositoryImpl(this._api, this._vault, this._publicApi);

  final AuthorizedApi _api;
  final AuthApi _publicApi;
  final ServerConfigVault _vault;

  @override
  Future<Either<AuthFailure, ServerConfig>> fetch() async {
    final config = await _api.request('GET', 'app-config');
    final json = config.fold((_) => null, (value) => value);
    if (json == null) return config.fold(left, (_) => left(_unavailable));
    // Currencies come with the signed-in config so screens never guess digits
    // or symbols (MOB-P5-001).
    final options = await _api.request('GET', 'profile/options');
    final currencies = options.fold(
      (_) => null,
      (value) => value['currencies'],
    );
    if (currencies == null) {
      return options.fold(left, (_) => left(_unavailable));
    }
    try {
      return right(ServerConfig.fromJson({...json, 'currencies': currencies}));
    } on Object {
      return left(_unavailable);
    }
  }

  static const _unavailable = AuthFailure(AuthError.unavailable);

  @override
  Future<Either<AuthFailure, ServerConfig>> fetchPublic() async {
    try {
      final json = await _publicApi.request('GET', 'app-config/public');
      return right(ServerConfig.fromJson({...json, 'flags': const {}}));
    } on AuthFailure catch (failure) {
      return left(failure);
    } on FormatException {
      return left(const AuthFailure(AuthError.unavailable));
    } catch (_) {
      return left(const AuthFailure(AuthError.network));
    }
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
