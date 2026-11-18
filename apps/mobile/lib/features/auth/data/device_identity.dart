import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The phone, as sent with a sign-in so the server keeps one session per
/// device (BE-P6-001 / MOB-P6-002).
abstract class DeviceIdentity {
  /// `{id, name, platform, osVersion}`, or null when it cannot be read: the
  /// sign-in then goes on without it.
  Future<Map<String, Object?>?> describe();
}

/// [id] is a random UUID made once. On iOS it sits in its own Keychain
/// service, so the fresh-install reset (MOB-P6-001) leaves it and a reinstall
/// replaces the old session instead of adding one. [name] is the model
/// ("iPhone 15 Pro"), never the name the person gave the phone.
class PlatformDeviceIdentity implements DeviceIdentity {
  const PlatformDeviceIdentity();

  static const _key = 'freeva.device-id.v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
    iOptions: IOSOptions(
      accountName: 'freeva_device',
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  @override
  Future<Map<String, Object?>?> describe() async {
    try {
      final String platform;
      final String? name;
      final String? osVersion;
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        platform = 'ios';
        name = ios.modelName;
        osVersion = ios.systemVersion;
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        platform = 'android';
        name = _androidName(android.manufacturer, android.model);
        osVersion = android.version.release;
      } else {
        return null;
      }
      var id = await _storage.read(key: _key);
      if (id == null || !uuidV4.hasMatch(id)) {
        id = newUuidV4();
        await _storage.write(key: _key, value: id);
      }
      return {
        'id': id,
        'name': _cut(name, 80),
        'platform': platform,
        'osVersion': _cut(osVersion, 32),
      };
    } catch (_) {
      return null;
    }
  }

  /// "samsung" + "SM-S918B" → "Samsung SM-S918B"; a model that already starts
  /// with the maker ("Pixel 8" by Google stays "Google Pixel 8").
  static String _androidName(String maker, String model) {
    final brand = maker.isEmpty
        ? ''
        : '${maker[0].toUpperCase()}${maker.substring(1)}';
    if (brand.isEmpty || model.toLowerCase().startsWith(maker.toLowerCase())) {
      return model;
    }
    return '$brand $model';
  }

  static String? _cut(String? value, int max) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.length <= max ? text : text.substring(0, max);
  }
}

final uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Random version-4 UUID from a secure source.
String newUuidV4([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
