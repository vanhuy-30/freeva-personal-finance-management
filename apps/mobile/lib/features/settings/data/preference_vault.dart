import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract class PreferenceVault {
  Future<String?> read();
  Future<void> write(String value);
}

@LazySingleton(as: PreferenceVault)
class SecurePreferenceVault implements PreferenceVault {
  SecurePreferenceVault()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device,
        ),
      );

  static const String storageKey = 'freeva.preferences.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);
}
