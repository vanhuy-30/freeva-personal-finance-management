import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/auth/data/auth_platform.dart';

import 'features/auth/fakes.dart';

import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/router/app_router.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/widgets/brand_symbol.dart';
import 'package:mobile/main.dart';

import 'support/server_config_fixture.dart';

import 'package:mobile/features/server_config/domain/server_config_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    resetAppRouter();
    await getIt.reset();
    await configureDependencies();
    await getIt.unregister<AppConfig>();
    getIt.registerSingleton<AppConfig>(
      AppConfig.fromValues(
        environment: 'dev',
        apiBaseUrl: 'https://api.example.test',
      ),
    );
    // No network in tests: the config download answers from memory.
    await getIt.unregister<ServerConfigRepository>();
    getIt.registerSingleton<ServerConfigRepository>(
      TestServerConfigRepository(),
    );
    await getIt.unregister<DeviceBiometrics>();
    getIt.registerSingleton<DeviceBiometrics>(FakeBiometrics());
    createAppRouter();
  });

  testWidgets('shows splash then login without exposing home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FreevaApp());
    await tester.pump();
    expect(find.byType(BrandSymbol), findsNWidgets(3));
    expect(find.text('FREEVA'), findsOneWidget);
    expect(find.text('Your money. Your freedom.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.textContaining('ví'), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.textContaining('ví'), findsNothing);
    // A fresh install opens on Welcome.
    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    // The logo lives on the splash only.
    expect(find.byType(BrandSymbol), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
