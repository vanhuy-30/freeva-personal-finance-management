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

void main() {
  late DefaultAuthViewModel model;
  setUp(() async {
    await getIt.reset();
    model = DefaultAuthViewModel(DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics())))
      ..ready = true;
    getIt.registerSingleton<AuthViewModel>(model);
  });
  tearDown(() async {
    model.dispose();
    await getIt.reset();
  });
  Widget app({String locale = 'vi', double textScale = 1}) => MaterialApp(
        locale: Locale(locale),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: const AuthGate(child: Text('protected content')),
      );
  testWidgets('background hides content immediately and resume requires unlock',
      (tester) async {
    model.stage = AuthStage.unlocked;
    await tester.pumpWidget(app());
    expect(find.text('protected content'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('protected content'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Freeva đã khóa'), findsOneWidget);
    expect(find.text('protected content'), findsNothing);
  });
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
  });
  testWidgets('PIN setup never renders protected content', (tester) async {
    model.stage = AuthStage.setupPin;
    await tester.pumpWidget(app());
    expect(find.text('Thiết lập PIN'), findsNWidgets(2));
    expect(find.text('protected content'), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
