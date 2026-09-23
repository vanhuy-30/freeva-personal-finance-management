import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/features/auth/data/auth_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('sessions are isolated by environment and API origin', () async {
    FlutterSecureStorage.setMockInitialValues({'freeva.auth.v1': 'legacy'});
    SecureAuthVault vault(String env, String url) => SecureAuthVault(
        AppConfig.fromValues(environment: env, apiBaseUrl: url));
    final dev = vault('dev', 'https://localhost:8443');
    final staging = vault('staging', 'https://localhost:8443');
    final otherHost = vault('dev', 'https://other.example.test');
    expect(await dev.read(), isNull);
    await dev.write('dev-session');
    expect(await staging.read(), isNull);
    expect(await otherHost.read(), isNull);
    await staging.write('staging-session');
    await dev.clear();
    expect(await dev.read(), isNull);
    expect(await staging.read(), 'staging-session');
    expect(await vault('staging', 'https://localhost:8443/').read(),
        'staging-session');
  });
}
