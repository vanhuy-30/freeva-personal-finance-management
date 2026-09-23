import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/features/auth/data/auth_platform.dart';
import 'features/auth/fakes.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/widgets/brand_symbol.dart';
import 'package:mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await getIt.reset();
    await configureDependencies();
    await getIt.unregister<AppConfig>();
    getIt.registerSingleton<AppConfig>(AppConfig.fromValues(
        environment: 'dev', apiBaseUrl: 'https://api.example.test'));
    await getIt.unregister<DeviceBiometrics>();
    getIt.registerSingleton<DeviceBiometrics>(FakeBiometrics());
  });

  testWidgets('shows splash then login without exposing home',
      (WidgetTester tester) async {
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
    expect(find.text('Bắt đầu cùng Freeva'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
    expect(find.text('Đặt lại mật khẩu'), findsNothing);
    expect(find.byType(BrandSymbol), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
