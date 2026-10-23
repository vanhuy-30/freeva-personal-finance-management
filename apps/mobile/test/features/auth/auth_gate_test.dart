import 'package:flutter/material.dart';
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
    deps = await registerSetupDeps();
    model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
    )..ready = true;
    getIt.registerSingleton<AuthViewModel>(model);
  });
  tearDown(() async {
    deps.settings.dispose();
    model.dispose();
    await getIt.reset();
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
    'first-run setup: email, three questions, wallets, PIN, then the app',
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
      expect(find.text('Bạn muốn cải thiện điều gì?'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn đang quản lý tiền thế nào?'), findsOneWidget);
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bạn muốn cải thiện điều gì?'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(find.text('Mỗi tháng bạn định chi bao nhiêu?'), findsOneWidget);
      await tester.tap(find.text('Thiết lập sau'));
      await tester.pumpAndSettle();
      expect(find.text('Tiền của bạn ở đâu?'), findsOneWidget);
      await tester.tap(find.text('Bỏ qua'));
      await tester.pumpAndSettle();
      expect(find.text('Đặt mã PIN'), findsOneWidget);
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(model.stage, AuthStage.unlocked);
      expect(find.text('protected content'), findsOneWidget);
      expect(deps.settings.onboardingCompleted, isTrue);
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
