import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../core/storage/secure_storage_factory.dart';

abstract class PreferenceVault {
  Future<String?> read();
  Future<void> write(String value);
}

@LazySingleton(as: PreferenceVault)
class SecurePreferenceVault implements PreferenceVault {
  SecurePreferenceVault() : _storage = createFreevaSecureStorage();

  static const String storageKey = 'freeva.preferences.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);
}
