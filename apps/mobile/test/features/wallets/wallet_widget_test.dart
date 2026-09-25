import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/wallets/presentation/widgets/wallet_editor.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';
import 'package:mobile/features/wallets/presentation/widgets/wallet_editor_form.dart';
import 'package:mobile/features/wallets/presentation/widgets/wallet_list.dart';

import '../auth/fakes.dart';
import 'wallet_test.dart' show WalletTransport;

void main() {
  late WalletTransport api;
  late DefaultAuthViewModel auth;
  late DefaultWalletViewModel model;
  setUp(() async {
    await getIt.reset();
    api = WalletTransport();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    getIt.registerSingleton<AuthViewModel>(auth);
    model = DefaultWalletViewModel(
      DefaultWalletUseCases(WalletRepositoryImpl(api)),
      auth,
    );
    await model.load();
  });
  tearDown(() async {
    model.dispose();
    auth.dispose();
    await getIt.reset();
  });
  Widget app(Widget child, {String locale = 'vi', double scale = 1}) =>
      MaterialApp(
        theme: AppTheme.light,
        locale: Locale(locale),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(body: child),
        ),
      );
  testWidgets('locking closes editor and discards financial draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListenableBuilder(
          listenable: model,
          builder: (_, _) => WalletList(model: model, archived: false),
        ),
      ),
    );
    await tester.tap(find.text('Sửa ví').first);
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditorForm), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Private draft');
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.byType(WalletEditor), findsNothing);
    expect(find.text('Private draft'), findsNothing);
    expect(model.wallets, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('wallet list renders exact balance, reorder and hidden filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        ListenableBuilder(
          listenable: model,
          builder: (_, _) => WalletList(model: model, archived: false),
        ),
      ),
    );
    expect(
      find.text('Số dư: 18.446.744.073.709.551.614 VND'),
      findsNWidgets(3),
    );
    await tester.tap(find.byTooltip('Di chuyển xuống').first);
    await tester.pumpAndSettle();
    expect(model.wallets.first.id, 'b');
    await tester.tap(find.text('Ẩn ví').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Ẩn ví'));
    await tester.pumpAndSettle();
    expect(find.text('b'), findsNothing);
    await tester.pumpWidget(
      app(WalletList(model: model, archived: true), locale: 'en'),
    );
    await tester.pumpAndSettle();
    expect(find.text('b'), findsOneWidget);
    expect(find.text('Restore wallet'), findsOneWidget);
  });
  testWidgets(
    'editor retains invalid draft and supports small screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(WalletEditorForm(model: model), scale: 2));
      await tester.enterText(find.byType(TextField).first, 'My wallet');
      await tester.enterText(find.byType(TextField).at(1), '1e3');
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(api.writes, 0);
      expect(find.text('My wallet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
