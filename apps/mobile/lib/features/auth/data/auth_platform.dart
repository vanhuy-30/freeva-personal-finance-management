import 'dart:convert';
import '../../../../core/config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

abstract class AuthVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

@LazySingleton(as: AuthVault)
class SecureAuthVault implements AuthVault {
  SecureAuthVault(AppConfig config)
      : _key = 'freeva.auth.v2.${config.environment.name}.'
            '${base64Url.encode(utf8.encode(Uri.parse(config.apiBaseUrl).origin))}';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions:
        IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  );
  final String _key;
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);
  @override
  Future<void> clear() => _storage.delete(key: _key);
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
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: false),
      );
}
