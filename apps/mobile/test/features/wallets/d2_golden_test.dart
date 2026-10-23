import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_editor_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show wallet;
import 'd1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/wallets/d2_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    Future<void> Function()? then,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await d1App(page, dark: dark, scale: scale));
    await tester.pump(const Duration(milliseconds: 300));
    if (then != null) await then();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/d2_$name.png'),
    );
  }

  WalletEditorPage editor({Wallet? editing}) =>
      WalletEditorPage(model: getIt(), wallet: editing);
  Widget lazy(WalletEditorPage Function() build) =>
      Builder(builder: (context) => build());

  Future<void> fillCard(WidgetTester tester) async {
    await tester.tap(find.text('Thẻ tín dụng'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), 'Thẻ chính');
    await tester.enterText(find.byType(TextField).at(1), '11450000');
    await tester.enterText(find.byType(TextField).at(2), '20000000');
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('add', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      lazy(editor),
      'add',
      then: () async {
        await tester.enterText(find.byType(TextField).first, 'Ví lương');
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('add dark', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, lazy(editor), 'add_dark', dark: true);
  });
  testWidgets('add card', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, lazy(editor), 'add_card', then: () => fillCard(tester));
  });
  testWidgets('add card compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      lazy(editor),
      'add_card_compact',
      scale: 1.3,
      size: const Size(320, 700),
      then: () => fillCard(tester),
    );
  });
  testWidgets('day popup', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      lazy(editor),
      'day_popup',
      then: () async {
        await fillCard(tester);
        await tester.tap(find.bySemanticsLabel('Ngày chốt, Chọn ngày'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('20'));
        await tester.pump();
        await tester.tap(find.text('Chọn ngày 20'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Đến hạn, Chọn ngày'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('25'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
  testWidgets('edit locked', skip: !Platform.isMacOS, (tester) async {
    final vcb = wallet('vcb', 'Vietcombank', balance: 55700000);
    final locked = Wallet(
      id: vcb.id,
      createdAt: vcb.createdAt,
      draft: WalletDraft(
        name: 'Vietcombank',
        type: WalletType.bank,
        currency: 'VND',
        initialBalance: BigInt.from(40000000),
      ),
      balance: vcb.balance,
      version: 1,
      sortOrder: 0,
      archived: false,
      hasTransactions: true,
    );
    await shot(tester, lazy(() => editor(editing: locked)), 'edit_locked');
  });
}
