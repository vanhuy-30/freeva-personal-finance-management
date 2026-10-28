import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/wallets/domain/wallet_flow.dart';
import 'package:mobile/features/wallets/presentation/pages/hidden_wallets_page.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_detail_page.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_page.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_sort_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show b;
import 'd1_stub.dart';

// macOS only (see core_widgets_golden_test.dart).
// Update: flutter test --update-goldens test/features/wallets/d1_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<void> shot(
    WidgetTester tester,
    Widget app,
    String name, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app);
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/d1_$name.png'),
    );
  }

  final flow = WalletFlow(moneyIn: b(18500000), moneyOut: b(1212000));
  const vcb = WalletDetailPage(walletId: 'vcb');
  const card = WalletDetailPage(walletId: 'card');

  testWidgets('list', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, await d1App(const WalletPage()), 'list');
  });
  testWidgets('list dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(const WalletPage(), dark: true),
      'list_dark',
    );
  });
  testWidgets('list compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(const WalletPage(), scale: 1.3),
      'list_compact',
      size: const Size(320, 700),
    );
  });
  testWidgets('sort', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, await d1App(const WalletSortPage()), 'sort');
  });
  testWidgets('detail', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(vcb, detail: StubWalletDetail(flow: flow)),
      'detail',
    );
  });
  testWidgets('detail dark', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(vcb, detail: StubWalletDetail(flow: flow), dark: true),
      'detail_dark',
    );
  });
  testWidgets('detail compact', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(vcb, detail: StubWalletDetail(flow: flow), scale: 1.3),
      'detail_compact',
      size: const Size(320, 700),
    );
  });
  testWidgets('credit', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(
        card,
        detail: StubWalletDetail(walletId: 'card', rows: creditRows()),
      ),
      'credit',
    );
  });
  testWidgets('hidden', skip: !Platform.isMacOS, (tester) async {
    await shot(tester, await d1App(const HiddenWalletsPage()), 'hidden');
  });
}
