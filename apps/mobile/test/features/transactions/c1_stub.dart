import 'package:flutter/material.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/tags/domain/tag.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_results_view_model.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';

import '../home/fixtures.dart' show b, wallet;
import '../home/home_fakes.dart' show FakeSyncViewModel;

TxLeg tx(
  String id, {
  required String account,
  required int amount,
  String day = '2026-10-21',
  TransactionType type = TransactionType.expense,
  String? category,
  String? merchant,
  String? notes,
  String? group,
  List<String> tags = const [],
  bool deleted = false,
}) => TxLeg(
  id: id,
  clientId: 'c-$id',
  accountId: account,
  currencyCode: 'VND',
  amountMinor: b(amount),
  type: type,
  occurredOn: day,
  categoryId: category,
  notes: notes,
  merchant: merchant,
  tagIds: tags,
  transferGroupId: group,
  deletedAt: deleted ? DateTime.utc(2026, 10, 21) : null,
  version: 1,
  createdAt: DateTime.utc(2026, 10, 21),
);

/// Rows like the C1 artboards.
List<TransactionBundle> canvasRows({bool deleted = false}) =>
    groupTransactionLegs([
      tx(
        '1',
        account: 'cash',
        amount: -65000,
        category: 'food',
        merchant: 'Phở Thìn',
        tags: ['work'],
        deleted: deleted,
      ),
      tx(
        '2',
        account: 'momo',
        amount: -55000,
        category: 'coffee',
        merchant: 'Highlands',
        deleted: deleted,
      ),
      tx(
        '3',
        account: 'momo',
        amount: -48000,
        category: 'bus',
        merchant: 'Grab',
        deleted: deleted,
      ),
      tx(
        '4',
        account: 'vcb',
        amount: 18500000,
        day: '2026-10-20',
        type: TransactionType.income,
        category: 'salary',
        merchant: 'Lương tháng 10',
        deleted: deleted,
      ),
      tx(
        '5',
        account: 'vcb',
        amount: -712000,
        day: '2026-10-20',
        category: 'bills',
        merchant: 'Điện EVN',
        deleted: deleted,
      ),
      tx(
        '6a',
        account: 'vcb',
        amount: -500000,
        day: '2026-10-20',
        type: TransactionType.transfer,
        notes: 'Nạp MoMo',
        group: 'g',
        deleted: deleted,
      ),
      tx(
        '6b',
        account: 'momo',
        amount: 500000,
        day: '2026-10-20',
        type: TransactionType.transfer,
        notes: 'Nạp MoMo',
        group: 'g',
        deleted: deleted,
      ),
    ]);

const stubCategories = [
  FinanceCategory(
    id: 'food',
    name: 'Ăn uống',
    parentId: null,
    iconToken: 'food',
  ),
  FinanceCategory(id: 'coffee', name: 'Cà phê', parentId: 'food'),
  FinanceCategory(
    id: 'bus',
    name: 'Đi lại',
    parentId: null,
    iconToken: 'transport',
  ),
  FinanceCategory(
    id: 'bills',
    name: 'Hóa đơn',
    parentId: null,
    iconToken: 'bills',
  ),
  FinanceCategory(
    id: 'salary',
    name: 'Thu nhập',
    parentId: null,
    iconToken: 'salary',
  ),
];

class StubTransactionViewModel extends ChangeNotifier
    implements TransactionViewModel {
  StubTransactionViewModel({
    List<TransactionBundle>? rows,
    this.filter = TransactionFilter.list,
  }) : rows = rows ?? canvasRows();

  @override
  List<TransactionBundle> rows;
  @override
  TransactionFilter filter;
  @override
  TransactionSummary summary = TransactionSummary(
    count: 6,
    totals: [
      TransactionTotal(
        currency: 'VND',
        income: b(18500000),
        expense: b(-880000),
      ),
    ],
  );
  @override
  List<Wallet> wallets = [
    wallet('cash', 'Tiền mặt', type: WalletType.cash),
    wallet('momo', 'MoMo', type: WalletType.ewallet),
    wallet('vcb', 'Vietcombank'),
  ];
  @override
  List<WalletCurrency> currencies = const [WalletCurrency('VND', 0)];
  @override
  List<FinanceCategory> categories = stubCategories;
  @override
  List<FinanceCategory> recentCategories = stubCategories;
  @override
  List<Tag> tags = [
    const Tag(id: 'work', clientId: 'c', name: 'Đi làm', version: 1),
  ];
  @override
  bool composerReady = true;
  @override
  bool listLoading = false;
  @override
  bool needsReload = false;
  @override
  bool hasMore = false;
  @override
  AuthFailure? failure;
  @override
  int fiscalDay = 1;
  @override
  String profileCurrency = 'VND';
  @override
  int get total => rows.length;
  @override
  String? today() => '2026-10-21';
  @override
  String? get timeZone => 'Asia/Ho_Chi_Minh';

  @override
  TransactionBundle? lastSaved;
  @override
  DateTime? lastSavedAt;
  @override
  String? preferredAccountId() => wallets.first.id;
  @override
  String? preferredCategoryId() => categories.first.id;
  int _ids = 0;
  @override
  String newClientId() => 'client-${_ids++}';
  final saved = <TransactionDraft>[];
  @override
  Future<bool> save(TransactionDraft draft, {TransactionBundle? existing}) async {
    saved.add(draft);
    return true;
  }

  final applied = <TransactionFilter>[];
  final removed = <TransactionBundle>[];
  final undone = <TransactionBundle>[];
  final restored = <TransactionBundle>[];
  int countValue = 24;

  @override
  Future<void> load() async {}
  @override
  Future<void> loadMore() async {}
  @override
  Future<void> setFilter(TransactionFilter value) async {
    filter = value;
    applied.add(value);
    notifyListeners();
  }

  @override
  Future<int?> countFor(TransactionFilter value) async => countValue;
  @override
  Future<int?> deletedCount() async => 4;
  @override
  Future<bool> remove(TransactionBundle bundle) async {
    removed.add(bundle);
    return true;
  }

  @override
  Future<bool> undoRemove(TransactionBundle bundle) async {
    undone.add(bundle);
    return true;
  }

  @override
  Future<bool> restore(TransactionBundle bundle) async {
    restored.add(bundle);
    return true;
  }

  @override
  TransactionQuery queryFor(
    TransactionFilter value, {
    int page = 1,
    int pageSize = 50,
    bool deleted = false,
  }) => value.toQuery(
    today: '2026-10-21',
    fiscalDay: 1,
    categories: categories,
    page: page,
    pageSize: pageSize,
    deleted: deleted,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubResults extends ChangeNotifier
    implements TransactionResultsViewModel {
  StubResults({
    this.rows = const [],
    this.filter = TransactionFilter.searching,
  });

  @override
  List<TransactionBundle> rows;
  @override
  TransactionFilter filter;
  @override
  TransactionSummary summary = TransactionSummary.empty;
  @override
  bool loading = false;
  @override
  bool hasMore = false;
  @override
  AuthFailure? failure;
  final searches = <String>[];

  @override
  void setSearch(String text) {
    searches.add(text);
    filter = filter.copyWith(search: text);
    notifyListeners();
  }

  @override
  Future<void> setFilter(TransactionFilter value) async {
    filter = value;
    notifyListeners();
  }

  @override
  Future<void> reload() async {}
  @override
  Future<void> loadMore() async {}
}

Future<Widget> c1App(
  Widget page, {
  required StubTransactionViewModel model,
  StubResults? results,
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  getIt.registerSingleton<TransactionViewModel>(model);
  getIt.registerSingleton<SyncViewModel>(FakeSyncViewModel());
  getIt.registerFactoryParam<TransactionResultsViewModel, bool, void>(
    (_, __) => results ?? StubResults(),
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

class TransactionSummaryStub {
  const TransactionSummaryStub();
  TransactionSummary get value => TransactionSummary(
    count: 1,
    totals: [
      TransactionTotal(
        currency: 'VND',
        income: BigInt.zero,
        expense: b(-65000),
      ),
    ],
  );
}
