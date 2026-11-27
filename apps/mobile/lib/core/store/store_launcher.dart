import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

/// Opens this app's page in the App Store or Play Store ("Cập nhật").
abstract class StoreLauncher {
  /// Whether this platform has a store page to open; the button is hidden
  /// when it does not (for example iOS before the app has a store id).
  bool get available;

  /// Opens the store page; false when nothing could be opened (no store app,
  /// a simulator, a sideloaded build). Never throws.
  Future<bool> open();
}

@LazySingleton(as: StoreLauncher)
class UrlStoreLauncher implements StoreLauncher {
  UrlStoreLauncher(this._config);

  final AppConfig _config;

  Uri? get _uri => _config.storeUri(defaultTargetPlatform);

  @override
  bool get available => _uri != null;

  @override
  Future<bool> open() async {
    final uri = _uri;
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
