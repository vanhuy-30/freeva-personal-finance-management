import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/pages/auth_page.dart';
import 'package:mobile/features/auth/presentation/pages/setup_page.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';

import 'fakes.dart';

void main() {
  late FakeApi api;
  late DefaultAuthViewModel model;
  setUp(() {
    api = FakeApi();
    model = DefaultAuthViewModel(
      DefaultAuthUseCases(
        AuthRepositoryImpl(api, MemoryVault(), FakeBiometrics()),
      ),
    );
  });
  tearDown(() => model.dispose());
  Widget app() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: ListenableBuilder(
      listenable: model,
      builder: (_, __) => AuthPage(model: model),
    ),
  );

  testWidgets(
    'sign-in has email and password on one screen, links and social',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app());
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      expect(find.text('Tiếp tục với Google'), findsOneWidget);
      expect(find.text('Tiếp tục với Apple'), findsOneWidget);
      await tester.tap(find.text('Đăng ký'));
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
    },
  );

  testWidgets('sign-up ticks the password list and needs the terms box', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    model.goTo(AuthStep.register);
    await tester.pumpWidget(app());
    final create = find.widgetWithText(TextButton, 'Tạo tài khoản');
    expect(tester.widget<TextButton>(create).onPressed, isNull);
    await tester.enterText(find.byType(TextField).at(0), 'lan@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'maytrangngay7');
    await tester.enterText(find.byType(TextField).at(2), 'maytrangngay7');
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Có cả chữ và số, đã đạt')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Hai mật khẩu khớp nhau, đã đạt')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('ký hiệu.*chưa đạt')), findsOneWidget);
    expect(tester.widget<TextButton>(create).onPressed, isNull);
    await tester.tap(find.bySemanticsLabel('Đồng ý điều khoản'));
    await tester.pump();
    expect(tester.widget<TextButton>(create).onPressed, isNotNull);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(model.stage, AuthStage.setup);
  });

  testWidgets(
    'every account screen fits 320 pt at large text in both languages',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final locale in ['vi', 'en']) {
        Widget screen(Widget home) => MaterialApp(
          theme: AppTheme.light,
          locale: Locale(locale),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: home,
        );
        for (final step in AuthStep.values) {
          model.goTo(step);
          await tester.pumpWidget(screen(AuthPage(model: model)));
          expect(tester.takeException(), isNull, reason: '$locale $step');
        }
        await tester.pumpWidget(screen(SetupPage(model: model)));
        expect(tester.takeException(), isNull, reason: '$locale verify');
        final done = find.text(locale == 'vi' ? 'Xong' : 'Done');
        await tester.ensureVisible(done);
        await tester.pumpAndSettle();
        await tester.tap(done);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$locale pin');
      }
    },
  );
}
