import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/domain/deep_link_service.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_link_host.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';

import '../../support/server_config_fixture.dart';
import '../settings/fakes.dart';
import '../sync/sync_fakes.dart';
import 'deep_link_service_test.dart' show FakeLinkSource;
import 'fakes.dart';

void main() {
  final token = 'ab12' * 16;
  const password = 'correct horse battery 7';
  late FakeApi api;
  late DefaultAuthViewModel auth;
  late FakeLinkSource source;
  late DeepLinkService service;
  late FixedSync sync;
  final navigatorKey = GlobalKey<NavigatorState>();

  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
    api = FakeApi();
    auth = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(
          api,
          MemoryVault(),
          FakeBiometrics(),
          testServerConfigModel(),
        ),
        testServerConfigModel(),
      ),
    );
    source = FakeLinkSource();
    service = DeepLinkService(source, RecordingLogger());
    sync = FixedSync([]);
    getIt
      ..registerSingleton<AuthViewModel>(auth)
      ..registerSingleton<DeepLinkService>(service)
      ..registerSingleton<SyncViewModel>(sync);
  });
  tearDown(() async {
    auth.dispose();
    service.dispose();
    await source.controller.close();
    await getIt.reset();
    registerTestServerConfig();
  });

  Widget app() => MaterialApp(
    navigatorKey: navigatorKey,
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    builder: (context, child) =>
        AuthLinkHost(navigatorKey: navigatorKey, child: child!),
    home: const Scaffold(body: Text('home')),
  );

  Future<void> signIn(WidgetTester tester) async {
    await tester.runAsync(() async {
      await auth.initialize();
      await auth.login('user@example.com', password);
    });
    expect(auth.stage, AuthStage.unlocked);
  }

  testWidgets('signed out: the link opens the reset screen, no dialog', (
    tester,
  ) async {
    await tester.runAsync(auth.initialize);
    await tester.pumpWidget(app());
    service.handle(Uri.parse('freeva://reset-password?token=$token'));
    await tester.pump();
    expect(auth.step, AuthStep.reset);
    expect(find.text('Đặt lại mật khẩu?'), findsNothing);
    expect(service.pending, isNull);
  });

  testWidgets('signed in: asks, then signs out and opens the reset screen', (
    tester,
  ) async {
    await signIn(tester);
    await tester.pumpWidget(app());
    service.handle(Uri.parse('freeva://reset-password?token=$token'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Đặt lại mật khẩu?'), findsOneWidget);
    expect(
      find.textContaining('Dữ liệu vẫn nằm trong tài khoản'),
      findsOneWidget,
    );
    expect(find.textContaining('chưa đồng bộ'), findsNothing);
    await tester.tap(find.text('Đặt lại'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(auth.stage, AuthStage.signedOut);
    expect(auth.step, AuthStep.reset);
    expect(find.text('Đặt lại mật khẩu?'), findsNothing);
  });

  testWidgets('warns when changes are still waiting to sync', (tester) async {
    await signIn(tester);
    sync.items = [syncItem('op-1')];
    await tester.pumpWidget(app());
    service.handle(Uri.parse('freeva://reset-password?token=$token'));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('chưa đồng bộ'), findsOneWidget);
  });

  testWidgets('cancel keeps the session', (tester) async {
    await signIn(tester);
    await tester.pumpWidget(app());
    service.handle(Uri.parse('freeva://reset-password?token=$token'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(auth.stage, AuthStage.unlocked);
    expect(service.pending, isNull);
    expect(find.text('Đặt lại mật khẩu?'), findsNothing);
  });

  testWidgets('a malformed link shows a notice', (tester) async {
    await tester.runAsync(auth.initialize);
    await tester.pumpWidget(app());
    service.handle(Uri.parse('freeva://reset-password?token=abc'));
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Link không hợp lệ. Hãy mở lại link trong email.'),
      findsOneWidget,
    );
    await tester.pumpAndSettle(const Duration(seconds: 7));
  });

  testWidgets(
    'a link that arrived before auth was ready is applied when it is',
    (tester) async {
      await tester.pumpWidget(app());
      service.handle(Uri.parse('freeva://reset-password?token=$token'));
      await tester.pump();
      expect(auth.step, isNot(AuthStep.reset));
      await tester.runAsync(auth.initialize);
      await tester.pump();
      expect(auth.step, AuthStep.reset);
    },
  );
}
