import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../core/storage/secure_storage_factory.dart';

abstract class ServerConfigVault {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

@LazySingleton(as: ServerConfigVault)
class SecureServerConfigVault implements ServerConfigVault {
  SecureServerConfigVault() : _storage = createFreevaSecureStorage();

  static const String storageKey = 'freeva.server_config.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: storageKey, value: value);

  @override
  Future<void> delete() => _storage.delete(key: storageKey);
}
