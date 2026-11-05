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

/// CSV the picker hands back unless a test says otherwise.
const sampleCsv =
    'Ngay,So tien,Loai,Nhom,Tai khoan,Ghi chu\n'
    '02/11/2026,65.000,Chi,An sang,Vi tien mat,Pho Thin\n'
    '02/11/2026,48.000,Chi,Di lai,MoMo,Grab\n'
    '05/10/2026,18.500.000,Thu,Luong,Techcombank,Luong thang 10\n';

class FakeImportWallets implements WalletUseCases {
  final wallets = [
    wallet('cash', 'Tiền mặt'),
    wallet('tcb', 'Techcombank'),
    wallet('old', 'Ví cũ', archived: true),
  ];
  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(wallets);
  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      right(const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeImportCategories implements CategoryUseCases {
  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() async => right(
    const CategoryCatalog(
      all: [
        FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null),
        FinanceCategory(id: 'salary', name: 'Lương', parentId: null),
        FinanceCategory(id: 'gone', name: 'Cũ', parentId: null, archived: true),
      ],
      recent: [],
    ),
  );
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
}) => ImportRow(
  rows: const [1],
  status: status,
  errors: errors,
  type: type,
  occurredOn: on,
  amountMinor: amount == null ? null : BigInt.from(amount),
  currencyCode: 'VND',
  merchant: merchant,
  accountId: account,
  categoryId: category,
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

  static ImportHarness create(List<ImportPreview> plans) {
    final useCases = FakeImportUseCases(plans);
    final picker = FakeImportPicker();
    final auth = FakeImportAuth();
    return ImportHarness._(
      useCases,
      picker,
      auth,
      DefaultImportViewModel(
        useCases,
        FakeImportWallets(),
        FakeImportCategories(),
        picker,
        auth,
      ),
    );
  }
}

/// The page on its own router, backed by the real view model.
Widget importApp(ImportHarness h, {bool dark = false, double scale = 1}) {
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
