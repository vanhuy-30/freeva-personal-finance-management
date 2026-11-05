import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/features/debts/presentation/pages/debt_detail_page.dart';
import 'package:mobile/features/debts/presentation/pages/debt_editor_page.dart';
import 'package:mobile/features/debts/presentation/pages/debts_page.dart';
import 'package:mobile/features/loans/presentation/pages/loan_detail_page.dart';
import 'package:mobile/features/loans/presentation/pages/loan_editor_page.dart';

import '../../core/widgets/widget_test_app.dart' show loadTestFonts;
import 'debt_stub.dart';

// macOS only. Each golden is read against the K board named in the test;
// compare with tool/design_compare (group K). Amounts are the stub's, the
// boards' figures are only examples.
// Update: flutter test --update-goldens test/features/debts/debts_golden_test.dart
void main() {
  setUpAll(loadTestFonts);
  tearDown(() => getIt.reset());

  Future<DebtHarness> shot(
    WidgetTester t,
    Widget page,
    String name, {
    bool dark = false,
    double scale = 1,
    Size size = const Size(390, 844),
    bool emptyDebts = false,
    bool emptyLoans = false,
    Future<void> Function(DebtHarness h)? then,
  }) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = (await t.runAsync(
      () => debtsApp(
        page,
        debts: emptyDebts ? const [] : null,
        loans: emptyLoans ? const [] : null,
        dark: dark,
        scale: scale,
      ),
    ))!;
    await t.pumpWidget(h.app);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    if (then != null) await then(h);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/debts_$name.png'),
    );
    return h;
  }

  Future<void> settle(WidgetTester t) async {
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
  }

  // DebtEmpty
  testWidgets('empty', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtsPage(), 'empty', emptyDebts: true);
  });
  testWidgets('empty dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtsPage(),
      'empty_dark',
      emptyDebts: true,
      dark: true,
    );
  });

  // DebtList
  testWidgets('list', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtsPage(), 'list');
  });
  testWidgets('list dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtsPage(), 'list_dark', dark: true);
  });
  testWidgets('list 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtsPage(),
      'list_scale',
      scale: 1.3,
      size: const Size(390, 1200),
    );
  });

  // DebtAdd
  testWidgets('add', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtEditorPage(),
      'add',
      then: (_) async {
        await t.enterText(find.byType(TextField).at(0), '3000000');
        await t.enterText(find.byType(TextField).at(1), 'Tuấn');
        await settle(t);
      },
    );
  });
  testWidgets('add dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtEditorPage(),
      'add_dark',
      dark: true,
      then: (_) async {
        await t.enterText(find.byType(TextField).at(0), '3000000');
        await t.enterText(find.byType(TextField).at(1), 'Tuấn');
        await settle(t);
      },
    );
  });
  testWidgets('add 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtEditorPage(),
      'add_scale',
      scale: 1.3,
      size: const Size(390, 1100),
    );
  });

  // DebtDetail
  testWidgets('detail', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtDetailPage(debtId: 'tuan'), 'detail');
  });
  testWidgets('detail dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtDetailPage(debtId: 'tuan'),
      'detail_dark',
      dark: true,
    );
  });
  testWidgets('detail borrowed', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtDetailPage(debtId: 'lan'), 'detail_borrowed');
  });

  // DebtPay
  Future<void> openPay(WidgetTester t) async {
    await t.tap(find.text('Ghi tiền nhận lại'));
    await t.pumpAndSettle();
    await t.tap(find.text('Một nửa'));
    await settle(t);
  }

  testWidgets('pay', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtDetailPage(debtId: 'tuan'),
      'pay',
      then: (_) => openPay(t),
    );
  });
  testWidgets('pay dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtDetailPage(debtId: 'tuan'),
      'pay_dark',
      dark: true,
      then: (_) => openPay(t),
    );
  });

  // LoanList
  testWidgets('loans', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtsPage(loans: true), 'loans');
  });
  testWidgets('loans dark', skip: !Platform.isMacOS, (t) async {
    await shot(t, const DebtsPage(loans: true), 'loans_dark', dark: true);
  });
  testWidgets('loans empty', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtsPage(loans: true),
      'loans_empty',
      emptyLoans: true,
    );
  });
  testWidgets('loans 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const DebtsPage(loans: true),
      'loans_scale',
      scale: 1.3,
      size: const Size(390, 1200),
    );
  });

  // LoanDetail (board is 980 high)
  testWidgets('loan detail', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanDetailPage(loanId: 'home'),
      'loan_detail',
      size: const Size(390, 980),
    );
  });
  testWidgets('loan detail dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanDetailPage(loanId: 'home'),
      'loan_detail_dark',
      dark: true,
      size: const Size(390, 980),
    );
  });

  // LoanAdd (board is 900 high)
  Future<void> fillLoan(WidgetTester t) async {
    await t.enterText(find.byType(TextField).at(1), '300000000');
    await t.enterText(find.byType(TextField).at(2), '210000000');
    await t.enterText(find.byType(TextField).at(3), '12');
    await t.enterText(find.byType(TextField).at(4), '6500000');
    await settle(t);
  }

  testWidgets('loan add', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanEditorPage(),
      'loan_add',
      size: const Size(390, 900),
      then: (_) => fillLoan(t),
    );
  });
  testWidgets('loan add dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanEditorPage(),
      'loan_add_dark',
      dark: true,
      size: const Size(390, 900),
      then: (_) => fillLoan(t),
    );
  });
  testWidgets('loan add 1.3x', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanEditorPage(),
      'loan_add_scale',
      scale: 1.3,
      size: const Size(390, 1400),
    );
  });

  // LoanPay
  Future<void> openLoanPay(WidgetTester t) async {
    await t.tap(find.text('Ghi lần trả'));
    await t.pumpAndSettle();
  }

  testWidgets('loan pay', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanDetailPage(loanId: 'home'),
      'loan_pay',
      size: const Size(390, 980),
      then: (_) => openLoanPay(t),
    );
  });
  testWidgets('loan pay dark', skip: !Platform.isMacOS, (t) async {
    await shot(
      t,
      const LoanDetailPage(loanId: 'home'),
      'loan_pay_dark',
      dark: true,
      size: const Size(390, 980),
      then: (_) => openLoanPay(t),
    );
  });
}
