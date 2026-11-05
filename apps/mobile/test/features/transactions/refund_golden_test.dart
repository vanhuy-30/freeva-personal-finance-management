import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/widgets/freeva_button.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show b;
import 'c1_stub.dart';

/// MOB-P3-008 boards `TxDetail3`, `TxRefund`, `TxRefundDelete` (group M).
/// Numbers come from the stub, not the boards.
// Update: flutter test --update-goldens test/features/transactions/refund_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  List<TransactionBundle> rows() => groupTransactionLegs([
    tx(
      'jacket',
      account: 'cash',
      amount: -890000,
      day: '2026-10-12',
      time: '19:20',
      category: 'shopping',
      merchant: 'Áo khoác',
      refunded: 300000,
    ),
    tx(
      'back',
      account: 'cash',
      amount: 300000,
      day: '2026-10-21',
      type: TransactionType.refund,
      category: 'shopping',
      refundOf: 'jacket',
    ),
    tx(
      'phone',
      account: 'momo',
      amount: -240000,
      day: '2026-10-12',
      category: 'shopping',
      merchant: 'Ốp điện thoại',
    ),
  ]);

  Future<void> pumpPage(
    WidgetTester tester,
    StubTransactionViewModel model, {
    bool dark = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await c1App(
        const TransactionPage(),
        model: model,
        dark: dark,
        scale: scale,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> golden(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/refund_$name.png'),
  );

  Future<void> openJacket(WidgetTester tester) async {
    await tester.tap(find.text('Áo khoác'));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    final suffix = dark ? '_dark' : '';
    testWidgets('list$suffix', skip: !Platform.isMacOS, (tester) async {
      await pumpPage(
        tester,
        StubTransactionViewModel(rows: rows()),
        dark: dark,
      );
      await golden('list$suffix');
    });

    testWidgets('expense detail$suffix', skip: !Platform.isMacOS, (
      tester,
    ) async {
      await pumpPage(
        tester,
        StubTransactionViewModel(rows: rows()),
        dark: dark,
      );
      await openJacket(tester);
      await golden('detail$suffix');
    });

    testWidgets('refund sheet$suffix', skip: !Platform.isMacOS, (tester) async {
      await pumpPage(
        tester,
        StubTransactionViewModel(rows: rows()),
        dark: dark,
      );
      await openJacket(tester);
      await tester.tap(find.text('Ghi hoàn tiền'));
      await tester.pumpAndSettle();
      await golden('sheet$suffix');
    });

    testWidgets('delete popup$suffix', skip: !Platform.isMacOS, (tester) async {
      await pumpPage(
        tester,
        StubTransactionViewModel(rows: rows()),
        dark: dark,
      );
      await openJacket(tester);
      await tester.tap(find.byTooltip('Xoá giao dịch'));
      await tester.pumpAndSettle();
      await golden('delete$suffix');
    });
  }

  testWidgets('refund sheet 1.3x', skip: !Platform.isMacOS, (tester) async {
    await pumpPage(tester, StubTransactionViewModel(rows: rows()), scale: 1.3);
    await openJacket(tester);
    await tester.tap(find.text('Ghi hoàn tiền'));
    await tester.pumpAndSettle();
    await golden('sheet_scale');
  });

  testWidgets('refund row detail', skip: !Platform.isMacOS, (tester) async {
    await pumpPage(tester, StubTransactionViewModel(rows: rows()));
    await tester.tap(find.text('Hoàn tiền'));
    await tester.pumpAndSettle();
    await golden('refund_detail');
  });

  group('behaviour', () {
    testWidgets('full refund chip fills what is left and saves it', (
      tester,
    ) async {
      final model = StubTransactionViewModel(rows: rows());
      await pumpPage(tester, model);
      await openJacket(tester);
      await tester.tap(find.text('Ghi hoàn tiền'));
      await tester.pumpAndSettle();
      expect(find.text('Đã chi 890.000 · 12/10'), findsOneWidget);
      await tester.tap(find.text('Hoàn toàn bộ 590.000'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FreevaButton, 'Ghi hoàn tiền'));
      await tester.pumpAndSettle();
      expect(model.refunds, [('jacket', 'cash', b(590000), '2026-10-21')]);
    });

    testWidgets('delete asks about refunds and sends the choice', (
      tester,
    ) async {
      final model = StubTransactionViewModel(rows: rows());
      await pumpPage(tester, model);
      await openJacket(tester);
      await tester.tap(find.byTooltip('Xoá giao dịch'));
      await tester.pumpAndSettle();
      expect(find.text('Khoản này đã được hoàn 300.000.'), findsOneWidget);
      await tester.tap(find.text('Giữ hoàn tiền'));
      await tester.pump();
      await tester.tap(find.text('Xoá').last);
      await tester.pumpAndSettle();
      expect(model.removedWith, [RefundDisposition.keep]);
    });

    testWidgets('an expense without refunds deletes straight away', (
      tester,
    ) async {
      final model = StubTransactionViewModel(rows: rows());
      await pumpPage(tester, model);
      await tester.tap(find.text('Ốp điện thoại'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Xoá giao dịch'));
      await tester.pumpAndSettle();
      expect(model.removedWith, [null]);
    });

    testWidgets('a refund has only Xoá and points to its expense', (
      tester,
    ) async {
      await pumpPage(tester, StubTransactionViewModel(rows: rows()));
      await tester.tap(find.text('Hoàn tiền'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn cho'), findsOneWidget);
      expect(find.text('Sửa'), findsNothing);
      expect(find.text('Sao chép'), findsNothing);
      expect(find.text('Ghi hoàn tiền'), findsNothing);
    });
  });
}
