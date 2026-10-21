import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/data/category_repository_impl.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/sync/domain/sync_use_cases.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/tags/data/tag_repository_impl.dart';
import 'package:mobile/features/tags/domain/tag_use_cases.dart';
import 'package:mobile/features/transactions/data/transaction_repository_impl.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_editor.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_form.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_list.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';
import 'package:mobile/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:mobile/core/money/money_text.dart';
import 'package:mobile/features/wallets/data/wallet_repository_impl.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import '../auth/fakes.dart';
import '../profile/fakes.dart';
import '../settings/fakes.dart' show MemoryPreferences;
import 'transaction_fakes.dart';
import 'transaction_view_model_test.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late ScriptedApi api;
  late DefaultAuthViewModel auth;
  late DefaultWalletViewModel wallets;
  late DefaultTransactionViewModel model;
  late DefaultSyncViewModel sync;

  setUp(() async {
    await getIt.reset();
    api = ScriptedApi();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    getIt.registerSingleton<AuthViewModel>(auth);
    final walletCases = DefaultWalletUseCases(WalletRepositoryImpl(api));
    wallets = DefaultWalletViewModel(walletCases, auth);
    final analytics = RecordingAnalytics();
    sync = DefaultSyncViewModel(
      DefaultSyncUseCases(MemorySyncRepository()),
      auth,
      analytics,
    );
    model = DefaultTransactionViewModel(
      DefaultTransactionUseCases(TransactionRepositoryImpl(api)),
      DefaultCategoryUseCases(CategoryRepositoryImpl(api)),
      DefaultTagUseCases(TagRepositoryImpl(api)),
      walletCases,
      wallets,
      ProfileUseCases(MemoryProfiles()),
      auth,
      analytics,
      sync,
    );
    await model.load();
  });

  tearDown(() async {
    model.dispose();
    sync.dispose();
    wallets.dispose();
    auth.dispose();
    await getIt.reset();
  });

  Widget app(Widget child, {double scale = 1}) => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  );

  testWidgets('editor keeps an invalid draft on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(TransactionForm(model: model), scale: 2));
    await tester.enterText(find.byType(TextField).first, '1e3');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    expect(api.writes, 0);
    expect(find.text('1e3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new expense focuses amount, prefers recent defaults, and pins save',
    (tester) async {
      await tester.pumpWidget(app(TransactionForm(model: model)));
      await tester.pumpAndSettle();
      final amountField = tester.widget<TextField>(find.byType(TextField).first);
      expect(amountField.autofocus, isTrue);
      expect(model.preferredAccountId(), 'card');
      expect(model.preferredCategoryId(), 'food');
      expect(find.text('Ăn uống'), findsWidgets);
      final scroll = find.byType(SingleChildScrollView);
      expect(
        find.descendant(
          of: scroll,
          matching: find.widgetWithText(FilledButton, 'Lưu'),
        ),
        findsNothing,
      );
      expect(find.widgetWithText(FilledButton, 'Lưu'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '25000');
      await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
      await tester.pumpAndSettle();
      expect(api.writes, 1);
    },
  );

  testWidgets('locking closes the editor and drops the draft', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TransactionEditor(model: model),
              ),
            ),
            child: const Text('Ghi'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ghi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '25000');
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.text('25000'), findsNothing);
    expect(find.byType(TransactionEditor), findsNothing);
    expect(model.wallets, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank merchant and a new tag still save', (tester) async {
    await tester.pumpWidget(app(TransactionForm(model: model)));
    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Work'));
    await tester.tap(find.widgetWithText(FilterChip, 'Work'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, 'Tạo nhãn'));
    await tester.tap(find.widgetWithText(ActionChip, 'Tạo nhãn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Family');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo nhãn'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    final post = api.calls.lastWhere(
      (call) => call.method == 'POST' && call.path == 'transactions',
    );
    expect(post.body!['merchant'], isNull);
    expect(post.body!['tagIds'], hasLength(2));
    expect(post.body!['tagIds'], contains('work'));
  });

  testWidgets('hidden balances mask the list but not the amount being typed', (
    tester,
  ) async {
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
    await tester.pumpWidget(app(TransactionList(model: model, onOpen: (_) {})));
    expect(find.textContaining('••••'), findsOneWidget);
    expect(
      find.textContaining(formatMoneyText(BigInt.from(-1000), 0, 'vi')),
      findsNothing,
    );
    await tester.pumpWidget(app(TransactionForm(model: model)));
    await tester.enterText(find.byType(TextField).first, '25000');
    expect(find.text('25000'), findsOneWidget);
    expect(find.textContaining('••••'), findsNothing);
  });
}
