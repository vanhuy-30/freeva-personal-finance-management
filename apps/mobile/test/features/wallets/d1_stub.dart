import 'package:flutter/material.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_results_view_model.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_flow.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_detail_view_model.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../home/fixtures.dart' show b, wallet;
import '../transactions/c1_stub.dart';
import 'package:mobile/core/money/display_converted.dart';

/// Credit card like the D artboards: debt 11.450.000 of 20.000.000, closes
/// on the 20th, due on the 25th.
Wallet creditCard({int balance = -11450000, int? limit = 20000000}) => Wallet(
  id: 'card',
  createdAt: DateTime.utc(2026),
  draft: WalletDraft(
    name: 'Thẻ chính',
    type: WalletType.credit,
    currency: 'VND',
    initialBalance: BigInt.zero,
    creditLimit: limit == null ? null : b(limit),
    closeDay: 20,
    dueDay: 25,
  ),
  balance: b(balance),
  version: 1,
  sortOrder: 3,
  archived: false,
);

/// Wallets of the D artboards; "Ví du lịch" is hidden.
List<Wallet> canvasWallets() => [
  wallet('vcb', 'Vietcombank', balance: 55700000),
  wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 1850000),
  wallet('momo', 'MoMo', type: WalletType.ewallet, balance: 2150000),
  creditCard(),
  wallet('trip', 'Ví du lịch', type: WalletType.cash, archived: true),
];

class StubWalletViewModel extends WalletViewModel {
  StubWalletViewModel({List<Wallet>? wallets, this.busy = false})
    : wallets = wallets ?? canvasWallets();

  @override
  List<Wallet> wallets;
  @override
  List<WalletCurrency> currencies = const [WalletCurrency('VND', 0)];
  @override
  bool busy;
  @override
  bool needsReload = false;
  @override
  AuthFailure? failure;
  @override
  String get mainCurrency => 'VND';
  @override
  DateTime get today => DateTime(2026, 10, 21);
  final reordered = <List<String>>[];
  final archived = <String>[];

  @override
  String newClientId() => 'client';
  @override
  Future<void> load() async {}
  @override
  Future<bool> save(
    WalletDraft draft,
    String clientId, {
    Wallet? wallet,
  }) async => true;
  @override
  Future<bool> archive(Wallet wallet) async {
    archived.add(wallet.id);
    return true;
  }

  @override
  Future<bool> reorder(List<Wallet> ordered) async {
    reordered.add([for (final w in ordered) w.id]);
    return true;
  }
}

/// Vietcombank's day on the WDetail artboard.
List<TransactionBundle> walletRows() => groupTransactionLegs([
  tx(
    's',
    account: 'vcb',
    amount: 18500000,
    day: '2026-10-20',
    type: TransactionType.income,
    category: 'salary',
    notes: 'Lương tháng 10',
  ),
  tx(
    'e',
    account: 'vcb',
    amount: -712000,
    day: '2026-10-20',
    category: 'bills',
  ),
  tx(
    't',
    account: 'vcb',
    amount: -500000,
    day: '2026-10-20',
    type: TransactionType.transfer,
    notes: 'Nạp MoMo',
    group: 'g',
  ),
]);

/// The card's day on the WCredit artboard.
List<TransactionBundle> creditRows() => groupTransactionLegs([
  tx(
    'coat',
    account: 'card',
    amount: -890000,
    day: '2026-10-18',
    category: 'shopping',
    merchant: 'Áo khoác',
  ),
  tx(
    'dinner',
    account: 'card',
    amount: -400000,
    day: '2026-10-18',
    category: 'food',
    merchant: 'Nhà hàng Ngon',
  ),
]);

class StubWalletDetail extends ChangeNotifier implements WalletDetailViewModel {
  StubWalletDetail({
    this.walletId = 'vcb',
    List<TransactionBundle>? rows,
    this.flow,
  }) : results = StubResults(rows: rows ?? walletRows());

  @override
  final String walletId;
  @override
  final StubResults results;
  @override
  WalletFlow? flow;
  @override
  bool flowFailed = false;
  @override
  DisplayConverted? converted;
  int reloads = 0;

  @override
  Future<void> reload() async => reloads++;
}

/// [page] with stub wallet, transaction and detail models in [getIt].
Future<Widget> d1App(
  Widget page, {
  StubWalletViewModel? model,
  StubWalletDetail? detail,
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  getIt.registerSingleton<AuthViewModel>(
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
        ),
      )
      ..stage = AuthStage.unlocked
      ..hasPin = true
      ..ready = true,
  );
  final wallets = model ?? StubWalletViewModel();
  getIt.registerSingleton<WalletViewModel>(wallets);
  getIt.registerSingleton<TransactionViewModel>(
    StubTransactionViewModel()
      ..wallets = wallets.wallets
      ..categories = [
        ...stubCategories,
        const FinanceCategory(
          id: 'shopping',
          name: 'Mua sắm',
          parentId: null,
          iconToken: 'shopping',
        ),
      ],
  );
  getIt.registerFactoryParam<WalletDetailViewModel, String, void>(
    (id, _) => detail ?? StubWalletDetail(walletId: id),
  );
  getIt.registerFactoryParam<TransactionResultsViewModel, bool, void>(
    (_, _) => StubResults(),
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: page,
    ),
  );
}
