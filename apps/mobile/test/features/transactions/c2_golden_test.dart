import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/composer/transaction_composer_screen.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show wallet;
import 'c1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/transactions/c2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    StubTransactionViewModel model,
    String name, {
    TransactionType? type,
    TransactionBundle? existing,
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      await c1App(
        TransactionComposerScreen(
          model: model,
          initialType: type,
          existing: existing,
        ),
        model: model,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    for (final key in ['6', '5', '000']) {
      if (existing == null) await tester.tap(find.bySemanticsLabel(key).last);
    }
    await tester.pump();
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/c2_$name.png'),
    );
  }

  testWidgets('expense', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, StubTransactionViewModel(), 'expense');
  });

  testWidgets('category sheet', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      StubTransactionViewModel(),
      'category',
      then: () async {
        await tester.tap(find.text('Tất cả'));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('details (edit)', skip: !Platform.isMacOS, (tester) async {
    final row = canvasRows().first;
    await shot(tester, StubTransactionViewModel(), 'details', existing: row);
  });

  testWidgets('tags sheet', skip: !Platform.isMacOS, (tester) async {
    final row = canvasRows().first;
    await shot(
      tester,
      StubTransactionViewModel(),
      'tags',
      existing: row,
      then: () async {
        await tester.ensureVisible(find.text('Thêm nhãn'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Thêm nhãn'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, 'Du lịch');
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('transfer across currencies', skip: !Platform.isMacOS, (
    tester,
  ) async {
    final model = StubTransactionViewModel()
      ..wallets = [
        wallet('vcb', 'Vietcombank'),
        wallet('usd', 'Tiền đô', currency: 'USD'),
      ]
      ..currencies = const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];
    await shot(
      tester,
      model,
      'transfer',
      type: TransactionType.transfer,
      then: () async {
        await tester.tap(find.bySemanticsLabel(RegExp('^Đến')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tiền đô').last);
        await tester.pumpAndSettle();
      },
    );
  });
}
