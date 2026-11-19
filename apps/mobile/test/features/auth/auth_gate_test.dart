import 'package:flutter/material.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/auth/presentation/widgets/auth_gate.dart';

import 'fakes.dart';
import 'setup_deps.dart';

void main() {
  late DefaultAuthViewModel model;
  late SetupDeps deps;
  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
    deps = await registerSetupDeps();
    model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(
          FakeApi(),
          MemoryVault(),
          FakeBiometrics(),
          testServerConfigModel(),
        ),
        testServerConfigModel(),
      ),
    )..ready = true;
    getIt.registerSingleton<AuthViewModel>(model);
  });
  tearDown(() async {
    deps.settings.dispose();
    model.dispose();
    await getIt.reset();
    registerTestServerConfig();
  });
  Widget app({String locale = 'vi', double textScale = 1}) => MaterialApp(
    locale: Locale(locale),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: const AuthGate(child: Text('protected content')),
  );
  testWidgets(
    'background hides content immediately and resume requires unlock',
    (tester) async {
      model
        ..stage = AuthStage.unlocked
        ..hasPin = true;
      await tester.pumpWidget(app());
      expect(find.text('protected content'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('protected content'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Nhập mã PIN'), findsOneWidget);
      expect(find.text('protected content'), findsNothing);
    },
  );
  testWidgets(
    'auth form works at large text size on small screen in both locales',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in ['vi', 'en']) {
        await tester.pumpWidget(app(locale: locale, textScale: 2));
        await tester.pumpAndSettle();
        expect(find.text('protected content'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'first-run setup: email, three questions, Hoàn tất, then the app',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      model.stage = AuthStage.setup;
      await tester.pumpWidget(app());
      expect(find.text('Xác nhận email'), findsOneWidget);
      expect(find.text('protected content'), findsNothing);
      await tester.tap(find.text('Xong'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn Freeva giúp gì cho mình?'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(
        find.text('Thu nhập hàng tháng của bạn là bao nhiêu?'),
        findsOneWidget,
      );
      // System back returns to the previous question.
      final dynamic widgetsApp = tester.state(find.byType(WidgetsApp));
      await widgetsApp.didPopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn Freeva giúp gì cho mình?'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Không muốn chia sẻ'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn đang hướng đến mục tiêu tài chính nào?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      // No wallets or PIN here any more: they live in the app.
      expect(
        find.text('Hành trình tài chính của bạn bắt đầu từ đây!'),
        findsOneWidget,
      );
      expect(deps.settings.onboardingCompleted, isTrue);
      await tester.tap(find.text('Khám phá Freeva'));
      await tester.pumpAndSettle();
      expect(model.stage, AuthStage.unlocked);
      expect(find.text('protected content'), findsOneWidget);
    },
  );
  testWidgets('without a PIN, backgrounding never locks the app', (
    tester,
  ) async {
    model.stage = AuthStage.unlocked;
    await tester.pumpWidget(app());
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('protected content'), findsOneWidget);
  });
}
