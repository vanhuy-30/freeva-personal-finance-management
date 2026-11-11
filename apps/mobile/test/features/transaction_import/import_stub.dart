import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/domain/category_use_cases.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transaction_import/domain/import_file_picker.dart';
import 'package:mobile/features/transaction_import/domain/import_models.dart';
import 'package:mobile/features/transaction_import/domain/import_use_cases.dart';
import 'package:mobile/features/transaction_import/presentation/pages/import_page.dart';
import 'package:mobile/features/transaction_import/presentation/viewmodels/import_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_use_cases.dart';

import '../home/fixtures.dart' show wallet;
import '../../support/server_config_fixture.dart';

/// CSV the picker hands back unless a test says otherwise.
const sampleCsv =
    'Ngay,So tien,Loai,Nhom,Tai khoan,Ghi chu\n'
    '02/11/2026,65.000,Chi,An sang,Vi tien mat,Pho Thin\n'
    '02/11/2026,48.000,Chi,Di lai,MoMo,Grab\n'
    '05/10/2026,18.500.000,Thu,Luong,Techcombank,Luong thang 10\n';

class FakeImportWallets implements WalletUseCases {
  FakeImportWallets([List<Wallet>? wallets])
    : wallets =
          wallets ??
          [
            wallet('cash', 'Tiền mặt'),
            wallet('tcb', 'Techcombank'),
            wallet('old', 'Ví cũ', archived: true),
          ];
  final List<Wallet> wallets;
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(wallets);
  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      right(const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeImportCategories implements CategoryUseCases {
  FakeImportCategories([this.catalog = defaultCatalog]);
  final CategoryCatalog catalog;

  static const defaultCatalog = CategoryCatalog(
    all: [
      FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null),
      FinanceCategory(id: 'salary', name: 'Lương', parentId: null),
      FinanceCategory(id: 'gone', name: 'Cũ', parentId: null, archived: true),
    ],
    recent: [],
  );

  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() async => right(catalog);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeImportPicker implements ImportFilePicker {
  String? text = sampleCsv;
  Uint8List? raw;
  String name = 'so-chi-tieu.csv';
  @override
  Future<PickedImportFile?> pick() async {
    if (raw != null) return PickedImportFile(name, raw!);
    if (text == null) return null;
    return PickedImportFile(name, Uint8List.fromList(utf8.encode(text!)));
  }
}

class FakeImportAuth implements AuthViewModel {
  int expired = 0;
  @override
  void sessionExpired() => expired++;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ImportRow importRow(
  ImportRowStatus status, {
  List<ImportRowError> errors = const [],
  String type = 'expense',
  String? on = '2026-11-02',
  int? amount = 65000,
  String? merchant = 'Phở Thìn',
  String? account = 'cash',
  String? category = 'food',
  int line = 1,
  ImportSuggestion? suggestion,
}) => ImportRow(
  rows: [line],
  status: status,
  errors: errors,
  type: type,
  occurredOn: on,
  amountMinor: amount == null ? null : BigInt.from(amount),
  currencyCode: 'VND',
  merchant: merchant,
  accountId: account,
  categoryId: category,
  suggestion: suggestion,
);

ImportBatch batch({int created = 241, int dup = 5, int invalid = 2}) =>
    ImportBatch(
      id: 'batch-1',
      createdCount: created,
      duplicateCount: dup,
      invalidCount: invalid,
      remainingCount: created,
      undone: false,
    );

/// Scripted server: `plans` are returned in order, the last one repeats.
class FakeImportUseCases implements ImportUseCases {
  FakeImportUseCases(this.plans);
  List<ImportPreview> plans;
  AuthFailure? failure;
  final previews = <ImportRequest>[];
  final commits = <({ImportRequest request, String batchClientId, bool dup})>[];
  final undone = <String>[];
  ImportResult? commitResult;
  int undoCount = 241;

  @override
  Future<Either<AuthFailure, ImportPreview>> preview(
    ImportRequest request,
  ) async {
    previews.add(request);
    if (failure != null) return left(failure!);
    return right(plans[(previews.length - 1).clamp(0, plans.length - 1)]);
  }

  @override
  Future<Either<AuthFailure, ImportResult>> commit(
    ImportRequest request, {
    required String batchClientId,
    required bool includeDuplicates,
  }) async {
    commits.add((
      request: request,
      batchClientId: batchClientId,
      dup: includeDuplicates,
    ));
    if (failure != null) return left(failure!);
    return right(commitResult ?? ImportResult(batch: batch(), rows: const []));
  }

  @override
  Future<Either<AuthFailure, ImportUndo>> undo(String batchId) async {
    undone.add(batchId);
    if (failure != null) return left(failure!);
    return right(ImportUndo(batch: batch(), undoneCount: undoCount));
  }
}

ImportPreview plan({
  int ready = 241,
  int duplicate = 5,
  int invalid = 2,
  int suggested = 0,
  List<String> wallets = const [],
  List<String> categories = const [],
  List<ImportRow>? rows,
  Map<String, String> columns = const {'wallet': 'Tai khoan'},
}) => ImportPreview(
  summary: ImportSummary(
    rowCount: ready + duplicate + invalid,
    ready: ready,
    duplicate: duplicate,
    invalid: invalid,
    suggested: suggested,
  ),
  unmappedWallets: wallets,
  unmappedCategories: categories,
  columns: columns,
  rows:
      rows ??
      [
        importRow(ImportRowStatus.ready),
        importRow(
          ImportRowStatus.duplicate,
          merchant: 'Grab',
          amount: 48000,
          category: null,
        ),
        importRow(
          ImportRowStatus.ready,
          type: 'income',
          merchant: 'Lương tháng 10',
          amount: 18500000,
          on: '2026-10-05',
          category: 'salary',
        ),
        importRow(
          ImportRowStatus.invalid,
          errors: const [ImportRowError.dateInvalid],
          merchant: 'Siêu thị',
          amount: 320000,
          on: null,
        ),
      ],
);

class ImportHarness {
  ImportHarness._(this.useCases, this.picker, this.auth, this.model);
  final FakeImportUseCases useCases;
  final FakeImportPicker picker;
  final FakeImportAuth auth;
  final DefaultImportViewModel model;

  static ImportHarness create(
    List<ImportPreview> plans, {
    List<Wallet>? wallets,
    CategoryCatalog catalog = FakeImportCategories.defaultCatalog,
  }) {
    final useCases = FakeImportUseCases(plans);
    final picker = FakeImportPicker();
    final auth = FakeImportAuth();
    return ImportHarness._(
      useCases,
      picker,
      auth,
      DefaultImportViewModel(
        useCases,
        FakeImportWallets(wallets),
        FakeImportCategories(catalog),
        picker,
        auth,
        testServerConfigModel(),
      ),
    );
  }
}

/// The page on its own router, backed by the real view model.
Widget importApp(ImportHarness h, {bool dark = false, double scale = 1}) {
  registerTestServerConfig();
  getIt.registerFactory<ImportViewModel>(() => h.model);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: const ImportPage(),
        ),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/transactions', builder: (_, _) => const SizedBox()),
    ],
  );
  return MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: router,
  );
}

// Board R.2 / R.3 (MOB-P5-E03) ---------------------------------------------

ImportSuggestion boardGuess(String id, String name, String icon) =>
    ImportSuggestion(
      categoryId: id,
      categoryName: name,
      iconToken: icon,
      source: ImportSuggestionSource.history,
      matchCount: 8,
    );

final boardWallets = [
  wallet('cash', 'Tiền mặt'),
  wallet('momo', 'MoMo'),
  wallet('card', 'Thẻ chính'),
];

const boardCatalog = CategoryCatalog(
  all: [
    FinanceCategory(
      id: 'food',
      name: 'Ăn uống',
      parentId: null,
      iconToken: 'food',
      kind: CategoryKind.expense,
    ),
    FinanceCategory(
      id: 'coffee',
      name: 'Cà phê',
      parentId: null,
      iconToken: 'coffee',
      kind: CategoryKind.expense,
    ),
    FinanceCategory(
      id: 'market',
      name: 'Đi chợ',
      parentId: null,
      iconToken: 'groceries',
      kind: CategoryKind.expense,
    ),
    FinanceCategory(
      id: 'shopping',
      name: 'Mua sắm',
      parentId: null,
      iconToken: 'shopping',
      kind: CategoryKind.expense,
    ),
    FinanceCategory(
      id: 'move',
      name: 'Đi lại',
      parentId: null,
      iconToken: 'transport',
      kind: CategoryKind.expense,
    ),
    FinanceCategory(
      id: 'salary',
      name: 'Lương',
      parentId: null,
      iconToken: 'salary',
      kind: CategoryKind.income,
    ),
  ],
  recent: [],
);

/// Board R.2: 241 / 5 / 2, "Gợi ý 18", five guessed rows. Highlands Coffee
/// appears six times in the file (lines 1 and 20–24; the last five have no
/// date, so the Gợi ý filter leaves them out).
ImportPreview boardSuggestPlan() {
  ImportRow guessed(
    int line,
    String merchant,
    String on,
    int amount,
    String account,
    ImportSuggestion guess,
  ) => importRow(
    ImportRowStatus.ready,
    line: line,
    merchant: merchant,
    on: on,
    amount: amount,
    account: account,
    category: guess.categoryId,
    suggestion: guess,
  );
  final coffee = boardGuess('coffee', 'Cà phê', 'coffee');
  return plan(
    suggested: 18,
    rows: [
      guessed(1, 'Highlands Coffee', '2026-11-03', 45000, 'cash', coffee),
      guessed(
        2,
        'Grab',
        '2026-11-03',
        62000,
        'momo',
        boardGuess('move', 'Đi lại', 'transport'),
      ),
      guessed(
        3,
        'Shopee',
        '2026-11-01',
        389000,
        'card',
        boardGuess('shopping', 'Mua sắm', 'shopping'),
      ),
      guessed(
        4,
        'WinMart',
        '2026-10-31',
        214000,
        'cash',
        boardGuess('market', 'Đi chợ', 'groceries'),
      ),
      guessed(
        5,
        'Circle K',
        '2026-10-30',
        38000,
        'momo',
        boardGuess('food', 'Ăn uống', 'food'),
      ),
      importRow(ImportRowStatus.ready, line: 6, merchant: 'Phở Thìn'),
      // Same shop further down, kept out of the Gợi ý list (no date).
      for (var line = 20; line < 25; line++)
        importRow(
          ImportRowStatus.invalid,
          errors: const [ImportRowError.dateInvalid],
          line: line,
          merchant: 'highlands coffee',
          on: null,
          amount: 45000,
          category: 'coffee',
          suggestion: coffee,
        ),
    ],
  );
}
