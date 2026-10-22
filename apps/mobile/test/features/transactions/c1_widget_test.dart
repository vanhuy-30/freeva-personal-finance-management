import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';
import 'package:mobile/features/transactions/presentation/pages/deleted_transactions_page.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_page.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_search_page.dart';

import 'c1_stub.dart';

void main() {
  tearDown(() => getIt.reset());

  Finder rich(String text) => find.textContaining(text, findRichText: true);

  testWidgets('C1.1 list: chips, totals, day groups with net, row naming', (
    tester,
  ) async {
    await tester.pumpWidget(
      await c1App(const TransactionPage(), model: StubTransactionViewModel()),
    );
    await tester.pump();
    expect(find.text('Giao dịch'), findsOneWidget);
    expect(find.text('Tháng 10'), findsOneWidget);
    expect(rich('+18.500.000'), findsWidgets);
    expect(rich('−880.000'), findsOneWidget);
    expect(find.text('Hôm nay · 21/10'), findsOneWidget);
    expect(find.text('−168.000'), findsOneWidget);
    expect(find.text('Thứ Ba · 20/10'), findsOneWidget);
    expect(find.text('+17.788.000'), findsOneWidget);
    expect(find.text('Phở Thìn'), findsOneWidget);
    expect(find.text('Ăn uống · Tiền mặt'), findsOneWidget);
    expect(find.text('Nạp MoMo'), findsOneWidget);
    expect(find.text('Vietcombank → MoMo'), findsOneWidget);
    expect(find.text('#Đi làm'.substring(1)), findsOneWidget);
  });

  testWidgets('type chip applies a filter', (tester) async {
    final model = StubTransactionViewModel();
    await tester.pumpWidget(await c1App(const TransactionPage(), model: model));
    await tester.tap(find.text('Thu'));
    await tester.pump();
    expect(model.applied.last.type?.name, 'income');
  });

  testWidgets('C1.3 filter sheet counts results and applies wallets', (
    tester,
  ) async {
    final model = StubTransactionViewModel();
    await tester.pumpWidget(await c1App(const TransactionPage(), model: model));
    await tester.tap(find.byTooltip('Bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('Xem 24 giao dịch'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await tester.tap(find.text('MoMo').last);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Xem 24 giao dịch'));
    await tester.pumpAndSettle();
    expect(model.applied.last.accountIds, {'momo'});
  });

  testWidgets('C1.4 no result: active chip with × and clear', (tester) async {
    final model = StubTransactionViewModel(
      rows: const [],
      filter: const TransactionFilter(accountIds: {'cash'}),
    );
    await tester.pumpWidget(await c1App(const TransactionPage(), model: model));
    await tester.pump();
    expect(find.text('Không có giao dịch phù hợp'), findsOneWidget);
    expect(find.bySemanticsLabel('Bỏ Tiền mặt'), findsOneWidget);
    await tester.tap(find.text('Xoá bộ lọc'));
    await tester.pump();
    expect(model.applied.last.narrowed, isFalse);
  });

  testWidgets('C1.5 detail sheet: delete shows an undo toast', (tester) async {
    final model = StubTransactionViewModel();
    await tester.pumpWidget(await c1App(const TransactionPage(), model: model));
    await tester.tap(find.text('Phở Thìn'));
    await tester.pumpAndSettle();
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Sao chép'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);
    await tester.tap(find.byTooltip('Xoá giao dịch'));
    await tester.pumpAndSettle();
    expect(model.removed, hasLength(1));
    expect(find.text('Đã xoá khoản chi'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pump();
    expect(model.undone, hasLength(1));
  });

  testWidgets('C1.2 search marks matches and shows count', (tester) async {
    final results = StubResults(rows: canvasRows().take(1).toList())
      ..filter = TransactionFilter.searching.copyWith(search: 'pho')
      ..summary = const TransactionSummaryStub().value;
    await tester.pumpWidget(
      await c1App(
        const TransactionSearchPage(),
        model: StubTransactionViewModel(),
        results: results,
      ),
    );
    await tester.pump();
    expect(find.text('Mọi lúc'), findsOneWidget);
    expect(rich('1 kết quả'), findsOneWidget);
    expect(rich('Phở'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'grab');
    expect(results.searches.last, 'grab');
  });

  testWidgets('C1.7 deleted list restores a row', (tester) async {
    final model = StubTransactionViewModel();
    final results = StubResults(rows: canvasRows(deleted: true));
    await tester.pumpWidget(
      await c1App(
        const DeletedTransactionsPage(),
        model: model,
        results: results,
      ),
    );
    await tester.pump();
    expect(
      find.text('Khôi phục để đưa giao dịch về danh sách.'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Khôi phục').first);
    await tester.pump();
    expect(model.restored, hasLength(1));
  });

  testWidgets('list fits 320 pt at 1.3× text', (tester) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await c1App(
        const TransactionPage(),
        model: StubTransactionViewModel(),
        scale: 1.3,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
