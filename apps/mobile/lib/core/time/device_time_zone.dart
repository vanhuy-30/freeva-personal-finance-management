import 'package:flutter_timezone/flutter_timezone.dart';

/// The phone's IANA time zone ("Asia/Ho_Chi_Minh"). The account follows it:
/// there is no time zone setting in the app.
abstract class DeviceTimeZone {
  /// Null when the platform cannot tell.
  Future<String?> current();
}

/// Reads the zone from the OS.
class SystemTimeZone implements DeviceTimeZone {
  const SystemTimeZone();

  @override
  Future<String?> current() async {
    try {
      final zone = (await FlutterTimezone.getLocalTimezone()).identifier;
      return zone.isEmpty ? null : zone;
    } catch (_) {
      // No plugin (tests, unsupported platform): keep the account's zone.
      return null;
    }
  }
}
