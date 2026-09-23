import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'fakes.dart';

void main() {
  late FakeApi api;
  late DefaultAuthViewModel model;
  setUp(() {
    api = FakeApi();
    model = DefaultAuthViewModel(DefaultAuthUseCases(
        AuthRepositoryImpl(api, MemoryVault(), FakeBiometrics())));
  });
  tearDown(() => model.dispose());
  Widget app() => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: ListenableBuilder(
          listenable: model, builder: (_, __) => AuthPage(model: model)));

  testWidgets(
      'entry shows only email; existing account reveals password and forgot link',
      (tester) async {
    await tester.pumpWidget(app());
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Quên mật khẩu'), findsNothing);
    expect(find.text('Đặt lại mật khẩu'), findsNothing);
    expect(find.text('Xác thực email'), findsNothing);
    await tester.enterText(
        find.byKey(const ValueKey('auth-email')), 'user@example.com');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(find.text('Quên mật khẩu'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu cùng Freeva'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'user@example.com');
  });
  testWidgets(
      'new account has confirm password and automatically enters verification',
      (tester) async {
    api.nextStep = 'register';
    await tester.pumpWidget(app());
    await tester.enterText(
        find.byKey(const ValueKey('auth-email')), 'new@example.com');
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo tài khoản Freeva'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Quên mật khẩu'), findsNothing);
    await tester.enterText(
        find.byType(TextField).at(0), 'correct horse battery');
    await tester.enterText(
        find.byType(TextField).at(1), 'correct horse battery');
    await tester.ensureVisible(find.text('Tạo tài khoản'));
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm tra email của bạn'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-code')), findsOneWidget);
    expect(find.text('Chưa nhận được mã? Gửi lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
