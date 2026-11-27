import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

enum AppEnvironment { dev, staging, prod }

@lazySingleton
class AppConfig {
  AppConfig()
    : this.fromValues(
        environment: const String.fromEnvironment(
          'APP_ENV',
          defaultValue: 'dev',
        ),
        apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
        devCaCertificate: const String.fromEnvironment('DEV_CA_CERT_BASE64'),
        sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
        iosStoreUrl: const String.fromEnvironment('STORE_URL_IOS'),
        androidStoreUrl: const String.fromEnvironment('STORE_URL_ANDROID'),
      );

  AppConfig.fromValues({
    required String environment,
    required this.apiBaseUrl,
    this.devCaCertificate = '',
    this.sentryDsn = '',
    this.iosStoreUrl = '',
    this.androidStoreUrl = '',
  }) : environment = AppEnvironment.values.firstWhere(
         (value) => value.name == environment,
         orElse: () => throw StateError('APP_ENV must be dev, staging or prod'),
       );

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String devCaCertificate;
  final String sentryDsn;

  /// App Store page (`STORE_URL_IOS`). Empty until the app has a store id;
  /// the update button is then hidden on iOS.
  final String iosStoreUrl;

  /// Play Store page (`STORE_URL_ANDROID`); falls back to the page of
  /// [androidPackage], which never changes.
  final String androidStoreUrl;
  static const androidPackage = 'com.vanhuy.freeva';

  /// Where to send someone who must update the app, or null when this
  /// platform has no store page configured.
  Uri? storeUri(TargetPlatform platform) {
    final raw = switch (platform) {
      TargetPlatform.iOS => iosStoreUrl,
      TargetPlatform.android =>
        androidStoreUrl.isNotEmpty
            ? androidStoreUrl
            : 'https://play.google.com/store/apps/details?id=$androidPackage',
      _ => '',
    };
    return raw.isEmpty ? null : Uri.tryParse(raw);
  }

  bool get sentryEnabled => sentryDsn.isNotEmpty;

  bool get allowsDevelopmentCertificates =>
      environment == AppEnvironment.dev &&
      !const bool.fromEnvironment('dart.vm.product') &&
      !const bool.fromEnvironment('dart.vm.profile');

  void validate() {
    if (devCaCertificate.isNotEmpty && !allowsDevelopmentCertificates) {
      throw StateError('Development CA is only allowed in debug dev builds');
    }
    for (final value in [iosStoreUrl, androidStoreUrl]) {
      final store = Uri.tryParse(value);
      if (value.isNotEmpty &&
          (store == null ||
              store.scheme != 'https' ||
              store.host.isEmpty ||
              store.userInfo.isNotEmpty)) {
        throw StateError('Store URLs must be https links');
      }
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError(
        'API_BASE_URL must be an HTTPS origin. '
        'Run with --dart-define-from-file=config/<environment>.json',
      );
    }
  }
}
