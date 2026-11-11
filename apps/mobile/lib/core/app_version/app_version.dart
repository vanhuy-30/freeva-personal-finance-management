import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// MOB-P5-001: the installed build's version, read from the package at boot
/// instead of a constant that drifts from `pubspec.yaml`.
@lazySingleton
class AppVersion {
  AppVersion();

  /// Tests: a fixed version without the platform channel.
  AppVersion.fixed(this.label);

  /// `version+build`, e.g. `0.0.1+1`; sent with feedback.
  String label = '';

  /// Shown to people ("Phiên bản 0.0.1"): no build number.
  String get display => label.split('+').first;

  Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    label = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  }
}
