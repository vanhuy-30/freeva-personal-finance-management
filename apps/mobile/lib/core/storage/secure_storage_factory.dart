import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared Keychain / Keystore options for Freeva vaults.
///
/// Android no longer uses EncryptedSharedPreferences (removed in
/// `flutter_secure_storage` 11). Installs that only ever used plugin 9.x may
/// need to sign in again after this upgrade.
FlutterSecureStorage createFreevaSecureStorage() {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
}
