import 'package:injectable/injectable.dart';

enum AppEnvironment { dev, staging, prod }

@lazySingleton
class AppConfig {
  AppConfig()
      : this.fromValues(
          environment:
              const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
          apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
          devCaCertificate: const String.fromEnvironment('DEV_CA_CERT_BASE64'),
        );

  AppConfig.fromValues(
      {required String environment,
      required this.apiBaseUrl,
      this.devCaCertificate = ''})
      : environment = AppEnvironment.values.firstWhere(
          (value) => value.name == environment,
          orElse: () =>
              throw StateError('APP_ENV must be dev, staging or prod'),
        );

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String devCaCertificate;

  bool get allowsDevelopmentCertificates =>
      environment == AppEnvironment.dev &&
      !const bool.fromEnvironment('dart.vm.product') &&
      !const bool.fromEnvironment('dart.vm.profile');

  void validate() {
    if (devCaCertificate.isNotEmpty && !allowsDevelopmentCertificates) {
      throw StateError('Development CA is only allowed in debug dev builds');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw StateError('API_BASE_URL must be an HTTPS origin. '
          'Run with --dart-define-from-file=config/<environment>.json');
    }
  }
}
