import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../support/server_config_fixture.dart';
import 'fakes.dart';

void main() {
  const password = 'correct horse battery 7';
  late FakeApi api;
  late DefaultAuthViewModel model;
  setUp(() async {
    await getIt.reset();
    registerTestServerConfig();
    api = FakeApi();
    model = DefaultAuthViewModel(
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
  });
  tearDown(() async {
    model.dispose();
    await getIt.reset();
    registerTestServerConfig();
  });

  Widget app() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: ListenableBuilder(
      listenable: model,
      builder: (_, __) => ResetPasswordPage(model: model),
    ),
  );

  testWidgets('an expired or used link offers a new one', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    model.startReset('a' * 64);
    await tester.pumpWidget(app());
    expect(find.text('Yêu cầu link mới'), findsNothing);

    await tester.enterText(find.byType(TextField).at(0), password);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.pump();
    api.failure = const AuthFailure(AuthError.invalidToken);
    await tester.tap(find.text('Lưu và đăng nhập'));
    await tester.pumpAndSettle();
    expect(
      find.text('Link không hợp lệ, đã dùng hoặc đã hết hạn.'),
      findsOneWidget,
    );
    expect(find.text('Yêu cầu link mới'), findsOneWidget);

    await tester.tap(find.text('Yêu cầu link mới'));
    await tester.pumpAndSettle();
    expect(model.step, AuthStep.forgot);
  });

  testWidgets('other failures do not offer a new link', (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    model.startReset('a' * 64);
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField).at(0), password);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.pump();
    api.failure = const AuthFailure(AuthError.network);
    await tester.tap(find.text('Lưu và đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Yêu cầu link mới'), findsNothing);
  });
}
