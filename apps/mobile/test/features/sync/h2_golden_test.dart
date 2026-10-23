import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/pages/sync_compare_page.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_duplicate_sheet.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_view_model.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../transactions/c1_stub.dart';
import 'sync_fakes.dart';

// macOS only. Update: flutter test --update-goldens test/features/sync/h2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  SyncQueueItem conflict({bool remove = false}) =>
      syncItem(
        'c',
        action: remove ? SyncAction.delete : SyncAction.update,
        serverId: 'srv-1',
        merchant: 'Phở Thìn',
        amount: remove ? null : -65000,
      ).copyWith(
        notes: 'Ăn với team',
        categoryId: 'food',
        status: SyncItemStatus.conflict,
        reason: SyncReason.changedElsewhere,
        server: SyncServerCopy(
          id: 'srv-1',
          version: 4,
          occurredOn: '2026-10-22',
          amountMinor: '-60000',
          currencyCode: 'VND',
          categoryId: 'food',
          merchant: 'Phở Thìn',
          updatedAt: DateTime(2026, 10, 22, 12, 50),
        ),
      );

  Future<void> shot(
    WidgetTester t,
    String name,
    Widget home, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark : AppTheme.light,
        locale: const Locale('vi'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: home,
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/h2_$name.png'),
    );
  }

  Future<void> register(FixedSync model) async {
    await getIt.reset();
    getIt
      ..registerSingleton<SyncViewModel>(model)
      ..registerSingleton<TransactionViewModel>(StubTransactionViewModel());
  }

  testWidgets('compare', skip: !Platform.isMacOS, (t) async {
    await register(FixedSync([conflict()]));
    await shot(t, 'compare', const SyncComparePage(opId: 'c'));
  });
  testWidgets('compare mine dark compact', skip: !Platform.isMacOS, (t) async {
    await register(FixedSync([conflict()]));
    await shot(
      t,
      'compare_compact',
      const SyncComparePage(opId: 'c'),
      dark: true,
      scale: 1.3,
      size: const Size(320, 1200),
      then: () async {
        await t.tap(find.text('Bản trên máy này'));
        await t.pump(const Duration(milliseconds: 300));
        await t.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('compare deleted', skip: !Platform.isMacOS, (t) async {
    await register(FixedSync([conflict(remove: true)]));
    await shot(t, 'compare_deleted', const SyncComparePage(opId: 'c'));
  });
  testWidgets('duplicate sheet', skip: !Platform.isMacOS, (t) async {
    final stub = StubTransactionViewModel();
    await register(FixedSync(const []));
    await shot(
      t,
      'duplicate',
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showSyncDuplicateSheet(
                context,
                recorded: stub.rows[0],
                existing: stub.rows[1],
                naming: TransactionNaming(
                  S.of(context),
                  categories: stub.categories,
                  wallets: stub.wallets,
                  tags: stub.tags,
                ),
                digitsOf: (_) => 0,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      then: () async {
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
      },
    );
  });
}
