import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';

void main() {
  test('staging and prod reject a development trust root', () {
    for (final env in ['staging', 'prod']) {
      final config = AppConfig.fromValues(
          environment: env,
          apiBaseUrl: 'https://api.example.test',
          devCaCertificate: 'local-ca');
      expect(config.validate, throwsStateError);
    }
  });

  test('supports each environment with an HTTPS origin', () {
    for (final environment in AppEnvironment.values) {
      final config = AppConfig.fromValues(
          environment: environment.name,
          apiBaseUrl: 'https://api.example.test');
      config.validate();
      expect(config.environment, environment);
    }
  });
  test('rejects unknown environments', () {
    expect(
        () => AppConfig.fromValues(environment: 'production', apiBaseUrl: ''),
        throwsStateError);
  });
  test('rejects missing, insecure or ambiguous origins without exposing values',
      () {
    for (final url in [
      '',
      'http://localhost:4000',
      'https://user:secret@api.test',
      'https://api.test/api',
      'https://api.test?token=secret',
      'https://api.test/#secret'
    ]) {
      final config = AppConfig.fromValues(environment: 'dev', apiBaseUrl: url);
      expect(
          config.validate,
          throwsA(isA<StateError>().having(
              (error) => error.message, 'message', isNot(contains('secret')))));
    }
  });
}
