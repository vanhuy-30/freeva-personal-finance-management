import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';
import 'package:mobile/features/transactions/presentation/pages/deleted_transactions_page.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_page.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_search_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'c1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/transactions/c1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    Widget app,
    String name, {
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/c1_$name.png'),
    );
  }

  testWidgets('list', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await c1App(const TransactionPage(), model: StubTransactionViewModel()),
      'list',
    );
  });

  testWidgets('list dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await c1App(
        const TransactionPage(),
        model: StubTransactionViewModel(),
        dark: true,
      ),
      'list_dark',
    );
  });

  testWidgets('no result', skip: !Platform.isMacOS, (tester) async {
    final model = StubTransactionViewModel(
      rows: const [],
      filter: const TransactionFilter(
        accountIds: {'cash'},
        categoryIds: {'bus'},
      ),
    );
    await shot(
      tester,
      await c1App(const TransactionPage(), model: model),
      'no_result',
    );
  });

  testWidgets('filter sheet', skip: !Platform.isMacOS, (tester) async {
    final model = StubTransactionViewModel(
      filter: const TransactionFilter(
        accountIds: {'cash', 'momo'},
        categoryIds: {'food', 'bus'},
      ),
    );
    await shot(
      tester,
      await c1App(const TransactionPage(), model: model),
      'filter',
      then: () async {
        await tester.tap(find.byTooltip('Bộ lọc đang bật'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('detail sheet', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await c1App(const TransactionPage(), model: StubTransactionViewModel()),
      'detail',
      then: () async {
        await tester.tap(find.text('Phở Thìn'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('search', skip: !Platform.isMacOS, (tester) async {
    final results = StubResults(rows: canvasRows().take(1).toList())
      ..filter = TransactionFilter.searching.copyWith(search: 'pho')
      ..summary = const TransactionSummaryStub().value;
    await shot(
      tester,
      await c1App(
        const TransactionSearchPage(),
        model: StubTransactionViewModel(),
        results: results,
      ),
      'search',
    );
  });

  testWidgets('deleted', skip: !Platform.isMacOS, (tester) async {
    final results = StubResults(rows: canvasRows(deleted: true));
    await shot(
      tester,
      await c1App(
        const DeletedTransactionsPage(),
        model: StubTransactionViewModel(),
        results: results,
      ),
      'deleted',
    );
  });
}
