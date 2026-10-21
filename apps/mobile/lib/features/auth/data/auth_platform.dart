import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/storage/secure_storage_factory.dart';

import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

abstract class AuthVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
  Future<String?> readSeenSessions();
  Future<void> writeSeenSessions(String value);
  Future<void> clearSeenSessions();
}

@LazySingleton(as: AuthVault)
class SecureAuthVault implements AuthVault {
  SecureAuthVault(AppConfig config)
    : _key = _scoped(config, 'freeva.auth.v2'),
      _seenKey = _scoped(config, 'freeva.seen-sessions.v1');

  static String _scoped(AppConfig config, String prefix) =>
      '$prefix.${config.environment.name}.'
      '${base64Url.encode(utf8.encode(Uri.parse(config.apiBaseUrl).origin))}';

  final _storage = createFreevaSecureStorage();
  final String _key;
  final String _seenKey;
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
  @override
  Future<String?> readSeenSessions() => _storage.read(key: _seenKey);
  @override
  Future<void> writeSeenSessions(String value) =>
      _storage.write(key: _seenKey, value: value);
  @override
  Future<void> clearSeenSessions() => _storage.delete(key: _seenKey);
}

abstract class DeviceBiometrics {
  Future<bool> available();
  Future<bool> authenticate(String reason);
}

@LazySingleton(as: DeviceBiometrics)
class LocalDeviceBiometrics implements DeviceBiometrics {
  final _auth = LocalAuthentication();
  @override
  Future<bool> available() async =>
      await _auth.canCheckBiometrics &&
      (await _auth.getAvailableBiometrics()).isNotEmpty;
  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(
    localizedReason: reason,
    options: const AuthenticationOptions(
      biometricOnly: true,
      stickyAuth: false,
    ),
  );
}
