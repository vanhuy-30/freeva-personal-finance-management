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
import 'package:mobile/features/transactions/presentation/widgets/composer/transaction_composer_screen.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_list_body.dart';
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
          ..hasPin = true
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

  // Saving shows a 6 s toast; settle the frames without waiting it out.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Widget editor() => app(TransactionComposerScreen(model: model));

  Future<void> keys(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      await tester.tap(find.bySemanticsLabel(label).last);
    }
    await tester.pump();
  }

  testWidgets('zero amount blocks saving on a narrow large-text screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      app(TransactionComposerScreen(model: model), scale: 1.3),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu khoản chi'));
    await settle(tester);
    expect(api.writes, 0);
    expect(find.text('Nhập số tiền trước khi lưu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'new expense: recent defaults, keypad amount, saved in five taps',
    (tester) async {
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();
      expect(model.preferredAccountId(), 'card');
      expect(find.text('Ăn uống'), findsWidgets);
      expect(find.text('card'), findsOneWidget);
      // 4 key taps + save: well under the 10 s target (QA-P1-001).
      await keys(tester, ['2', '5', '000']);
      expect(find.text('25.000'), findsOneWidget);
      await tester.tap(find.text('Lưu khoản chi'));
      await settle(tester);
      expect(api.writes, 1);
      final post = api.calls.lastWhere(
        (call) => call.method == 'POST' && call.path == 'transactions',
      );
      final legs = (post.body!['legs'] as List).cast<Map<String, dynamic>>();
      expect(legs.single['amountMinor'], '-25000');
      expect(post.body!['categoryId'], 'food');
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
    await keys(tester, ['2', '5']);
    auth.lock();
    await tester.pumpAndSettle();
    expect(find.text('25'), findsNothing);
    expect(find.byType(TransactionEditor), findsNothing);
    expect(model.wallets, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank merchant and a new tag still save', (tester) async {
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    await keys(tester, ['2', '5', '000']);
    await tester.ensureVisible(find.text('Ghi chú, cửa hàng, nhãn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ghi chú, cửa hàng, nhãn'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng'), findsOneWidget);
    await tester.ensureVisible(find.text('Thêm nhãn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm nhãn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Work'));
    await tester.enterText(find.byType(TextField).last, 'Family');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo nhãn “Family”'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.text('Family'), findsOneWidget);
    await tester.tap(find.text('Lưu khoản chi'));
    await settle(tester);
    final post = api.calls.lastWhere(
      (call) => call.method == 'POST' && call.path == 'transactions',
    );
    expect(post.body!['merchant'], isNull);
    expect(post.body!['tagIds'], hasLength(2));
    expect(post.body!['tagIds'], contains('work'));
  });

  testWidgets('transfer posts two balanced legs', (tester) async {
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển'));
    await tester.pumpAndSettle();
    await keys(tester, ['5', '000']);
    await tester.tap(find.bySemanticsLabel(RegExp('^Đến')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('cash').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu chuyển ví'));
    await settle(tester);
    final post = api.calls.lastWhere(
      (call) => call.method == 'POST' && call.path == 'transactions',
    );
    final legs = (post.body!['legs'] as List).cast<Map<String, dynamic>>();
    expect(legs.map((l) => l['amountMinor']), ['-5000', '5000']);
    expect(post.body!['fx'], isNull);
  });

  testWidgets('closing a dirty form asks first', (tester) async {
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    await keys(tester, ['9']);
    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ khoản chi đang nhập?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục nhập'));
    await tester.pumpAndSettle();
    expect(find.text('9'), findsWidgets);
  });

  testWidgets('hiding balances keeps transaction amounts visible', (
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
    await tester.pumpWidget(app(TransactionListBody(model: model)));
    await tester.pump();
    expect(find.textContaining('••••', findRichText: true), findsNothing);
    expect(
      find.textContaining(
        formatMoneyText(BigInt.from(1000), 0, 'vi'),
        findRichText: true,
      ),
      findsWidgets,
    );
    await tester.pumpWidget(editor());
    await tester.pumpAndSettle();
    await keys(tester, ['2', '5', '000']);
    expect(find.text('25.000'), findsOneWidget);
  });
}
