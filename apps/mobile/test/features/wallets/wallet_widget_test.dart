import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/wallets/presentation/widgets/wallet_editor.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
import 'package:mobile/features/wallets/presentation/pages/hidden_wallets_page.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_sort_page.dart';
import 'package:mobile/features/wallets/presentation/widgets/wallet_list_body.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';

import '../auth/fakes.dart';
import '../settings/fakes.dart';
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

  /// [page] pushed over a stand-in list, so popOrGo can pop.
  Widget routed(Widget page) => MaterialApp.router(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: GoRouter(
      initialLocation: '/wallets/page',
      routes: [
        GoRoute(
          path: '/wallets',
          builder: (_, _) => const Text('list'),
          routes: [GoRoute(path: 'page', builder: (_, _) => page)],
        ),
      ],
    ),
  );
  Widget list({bool hidden = false}) => ListenableBuilder(
    listenable: model,
    builder: (_, _) =>
        WalletListBody(model: model, hidden: hidden, onAdd: () {}),
  );
  testWidgets('locking closes editor and discards financial draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    WalletEditor(model: model, wallet: model.wallets.first),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
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
  testWidgets('wallet list shows the total, exact balances and hidden link', (
    tester,
  ) async {
    await model.archive(model.wallets[1]);
    await tester.pumpWidget(app(list()));
    expect(find.text('Tổng số dư · 2 ví'), findsOneWidget);
    expect(find.text('18.446.744.073.709.551.614'), findsNWidgets(2));
    expect(find.text('36.893.488.147.419.103.228 ₫'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);
    expect(find.text('b'), findsNothing);
    expect(find.bySemanticsLabel('Ví đã ẩn, 1'), findsOneWidget);
  });
  testWidgets('hidden balances mask the list, not the type or name', (
    tester,
  ) async {
    await tester.pumpWidget(app(list(hidden: true)));
    expect(find.textContaining('18.446'), findsNothing);
    expect(find.text('••••••'), findsNWidgets(3));
    expect(find.text('a'), findsOneWidget);
  });
  testWidgets('empty list offers to add a wallet; no sort for one wallet', (
    tester,
  ) async {
    for (final w in [...model.wallets]) {
      await model.archive(w);
    }
    await tester.pumpWidget(app(list()));
    expect(find.text('Chưa có ví'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsNothing);
  });
  testWidgets('sort page moves with arrows and saves once on Xong', (
    tester,
  ) async {
    getIt.registerSingleton<WalletViewModel>(model);
    await tester.pumpWidget(routed(const WalletSortPage()));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Đưa a lên'), findsOneWidget);
    final up = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, LucideIcons.chevronUp).first,
    );
    expect(up.onPressed, isNull);
    await tester.tap(find.byTooltip('Đưa c lên'));
    await tester.pump();
    expect(api.writes, 0);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(api.writes, 1);
    expect(model.active.map((w) => w.id), ['a', 'c', 'b']);
    expect(find.text('list'), findsOneWidget);
  });
  testWidgets('hidden wallets page restores with a toast', (tester) async {
    getIt.registerSingleton<WalletViewModel>(model);
    await model.archive(model.wallets[2]);
    await tester.pumpWidget(app(const HiddenWalletsPage()));
    expect(
      find.text('Lịch sử vẫn giữ, khôi phục lúc nào cũng được.'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Khôi phục c'));
    // The empty state animates; settle only the toast.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(model.hidden, isEmpty);
    expect(find.text('Đã khôi phục c'), findsOneWidget);
  });
  testWidgets('hidden balances leave the editor visible', (tester) async {
    final settings = DefaultSettingsViewModel(
      DefaultSettingsUseCases(SettingsRepositoryImpl(MemoryPreferences())),
      DefaultAuthUseCases(
        AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
      ),
      RecordingAnalytics(),
    );
    await settings.load();
    await settings.setBalancesHidden(true);
    getIt.registerSingleton<SettingsViewModel>(settings);
    addTearDown(settings.dispose);
    await tester.pumpWidget(
      app(WalletEditorForm(model: model, wallet: model.wallets.first)),
    );
    await tester.pump();
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields.any((field) => (field.controller?.text ?? '').contains('•')),
      isFalse,
    );
    expect(
      fields.any(
        (field) => RegExp(r'\d').hasMatch(field.controller?.text ?? ''),
      ),
      isTrue,
    );
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
