import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';
import 'package:mobile/features/installments/presentation/pages/installment_add_page.dart';
import 'package:mobile/features/installments/presentation/pages/installment_detail_page.dart';
import 'package:mobile/features/installments/presentation/viewmodels/installment_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/pages/transaction_page.dart';
import 'package:mobile/features/wallets/presentation/pages/wallet_detail_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import '../home/fixtures.dart' show b;
import '../transactions/c1_stub.dart';
import '../wallets/d1_stub.dart';
import 'installment_stub.dart';

/// MOB-P3-009 boards `InstAdd`, `InstDetail`, `WCredit3`, `TxDetail3`
/// (group M). Numbers come from the stub, not the boards.
// Update: flutter test --update-goldens test/features/installments/installment_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  final card = creditCard(balance: -35450000, limit: 50000000);

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
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/installment_$name.png'),
    );
  }

  final purchase = InstallmentPurchase(
    transactionId: 'tx-phone',
    accountId: 'card',
    title: 'Điện thoại',
    icon: LucideIcons.smartphone,
    walletName: 'Thẻ chính',
    occurredOn: '2026-10-12',
    amountMinor: b(24000000),
    currency: 'VND',
  );

  Future<Widget> addApp(
    FakeInstallmentUseCases fake, {
    bool dark = false,
    double scale = 1,
  }) => d1App(
    Builder(
      builder: (_) => InstallmentAddPage(
        model: getIt<InstallmentViewModel>(),
        purchase: purchase,
      ),
    ),
    model: StubWalletViewModel(wallets: [card]),
    installments: fake,
    dark: dark,
    scale: scale,
  );

  for (final dark in [false, true]) {
    final suffix = dark ? '_dark' : '';
    testWidgets('add$suffix', skip: !Platform.isMacOS, (tester) async {
      await shot(
        tester,
        await addApp(FakeInstallmentUseCases(), dark: dark),
        'add$suffix',
      );
    });

    testWidgets('detail$suffix', skip: !Platform.isMacOS, (tester) async {
      await shot(
        tester,
        await d1App(
          const InstallmentDetailPage(planId: 'plan-1'),
          model: StubWalletViewModel(wallets: [card]),
          installments: FakeInstallmentUseCases(
            details: {'plan-1': phonePlan()},
          ),
          dark: dark,
        ),
        'detail$suffix',
      );
    });

    testWidgets('card$suffix', skip: !Platform.isMacOS, (tester) async {
      await shot(
        tester,
        await d1App(
          const WalletDetailPage(walletId: 'card'),
          model: StubWalletViewModel(wallets: [card]),
          detail: StubWalletDetail(walletId: 'card', rows: creditRows()),
          installments: FakeInstallmentUseCases(
            plans: [phonePlan(withPeriods: false)],
            thisPeriod: b(4000000),
            later: b(16000000),
          ),
          dark: dark,
        ),
        'card$suffix',
        size: const Size(390, 920),
      );
    });
  }

  testWidgets('add 1.3x', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await addApp(FakeInstallmentUseCases(), scale: 1.3),
      'add_scale',
      size: const Size(320, 700),
    );
  });

  testWidgets('closed plan', skip: !Platform.isMacOS, (tester) async {
    await shot(
      tester,
      await d1App(
        const InstallmentDetailPage(planId: 'plan-1'),
        model: StubWalletViewModel(wallets: [card]),
        installments: FakeInstallmentUseCases(
          details: {'plan-1': phonePlan(active: false)},
        ),
      ),
      'closed',
    );
  });

  testWidgets('expense detail with both actions', skip: !Platform.isMacOS, (
    tester,
  ) async {
    final model = StubTransactionViewModel(
      rows: groupTransactionLegs([
        tx(
          'phone',
          account: 'card',
          amount: -24000000,
          day: '2026-10-12',
          time: '19:20',
          category: 'shopping',
          merchant: 'Điện thoại',
        ),
      ]),
    )..wallets = [...StubTransactionViewModel().wallets, card];
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await c1App(const TransactionPage(), model: model));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Điện thoại'));
    await tester.pumpAndSettle();
    expect(find.text('Chuyển thành trả góp'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/installment_tx_detail.png'),
    );
  });

  group('behaviour', () {
    testWidgets('changing the count previews again and creates that draft', (
      tester,
    ) async {
      final fake = FakeInstallmentUseCases(
        details: {'plan-1': phonePlan(remaining: 6)},
      );
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await addApp(fake));
      await tester.pumpAndSettle();
      expect(fake.previews.single.installmentCount, 6);
      expect(fake.previews.single.firstDueOn, '2026-10-25');
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();
      expect(fake.previews.last.installmentCount, 12);
      expect(find.text('2.000.000'), findsWidgets);
      await tester.tap(find.text('Tạo lịch trả góp'));
      await tester.pumpAndSettle();
      expect(fake.created?.installmentCount, 12);
      expect(fake.created?.installmentMinor, isNull);
      expect(fake.createdClientId, isNotNull);
      expect(find.byType(InstallmentDetailPage), findsOneWidget);
    });

    testWidgets('closing asks first, then closes the plan', (tester) async {
      final fake = FakeInstallmentUseCases(details: {'plan-1': phonePlan()});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        await d1App(
          const InstallmentDetailPage(planId: 'plan-1'),
          model: StubWalletViewModel(wallets: [card]),
          installments: fake,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kết thúc trả góp'));
      await tester.pumpAndSettle();
      expect(fake.closed, isNull);
      await tester.tap(find.text('Kết thúc'));
      await tester.pumpAndSettle();
      expect(fake.closed?.id, 'plan-1');
    });
  });
}
