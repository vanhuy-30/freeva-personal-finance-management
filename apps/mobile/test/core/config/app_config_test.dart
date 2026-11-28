import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';

void main() {
  test('staging and prod reject a development trust root', () {
    for (final env in ['staging', 'prod']) {
      final config = AppConfig.fromValues(
        environment: env,
        apiBaseUrl: 'https://api.example.test',
        devCaCertificate: 'local-ca',
      );
      expect(config.validate, throwsStateError);
    }
  });

  test('supports each environment with an HTTPS origin', () {
    for (final environment in AppEnvironment.values) {
      final config = AppConfig.fromValues(
        environment: environment.name,
        apiBaseUrl: 'https://api.example.test',
      );
      config.validate();
      expect(config.environment, environment);
    }
  });
  test('rejects unknown environments', () {
    expect(
      () => AppConfig.fromValues(environment: 'production', apiBaseUrl: ''),
      throwsStateError,
    );
  });
  test(
    'rejects missing, insecure or ambiguous origins without exposing values',
    () {
      for (final url in [
        '',
        'http://localhost:4000',
        'https://user:secret@api.test',
        'https://api.test/api',
        'https://api.test?token=secret',
        'https://api.test/#secret',
      ]) {
        final config = AppConfig.fromValues(
          environment: 'dev',
          apiBaseUrl: url,
        );
        expect(
          config.validate,
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              isNot(contains('secret')),
            ),
          ),
        );
      }
    },
  );

  group('store pages', () {
    AppConfig make({String ios = '', String android = ''}) =>
        AppConfig.fromValues(
          environment: 'prod',
          apiBaseUrl: 'https://api.example.test',
          iosStoreUrl: ios,
          androidStoreUrl: android,
        );

    test('Android falls back to the page of the app id, iOS has none', () {
      final config = make();
      expect(
        config.storeUri(TargetPlatform.android).toString(),
        'https://play.google.com/store/apps/details?id=com.vanhuy.freeva',
      );
      expect(config.storeUri(TargetPlatform.iOS), isNull);
      expect(config.storeUri(TargetPlatform.macOS), isNull);
    });

    test('configured pages win', () {
      final config = make(
        ios: 'https://apps.apple.com/app/id123',
        android: 'https://play.google.com/store/apps/details?id=other',
      );
      expect(
        config.storeUri(TargetPlatform.iOS).toString(),
        'https://apps.apple.com/app/id123',
      );
      expect(
        config.storeUri(TargetPlatform.android).toString(),
        'https://play.google.com/store/apps/details?id=other',
      );
    });

    test('only https pages without credentials are accepted', () {
      make(ios: 'https://apps.apple.com/app/id123').validate();
      for (final bad in [
        'http://apps.apple.com/app/id123',
        'itms-apps://apps.apple.com/app/id123',
        'https://user:pw@apps.apple.com/app/id123',
        'not a url',
      ]) {
        expect(make(ios: bad).validate, throwsStateError, reason: bad);
        expect(make(android: bad).validate, throwsStateError, reason: bad);
      }
    });
  });
}
