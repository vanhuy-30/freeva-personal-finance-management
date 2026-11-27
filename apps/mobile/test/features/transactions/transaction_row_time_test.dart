import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_day_list.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';

import 'c1_stub.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    StubTransactionViewModel stub,
    List<TransactionBundle> rows,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: SingleChildScrollView(
              child: TransactionDayList(
                rows: rows,
                naming: TransactionNaming(
                  S.of(context),
                  categories: stub.categories,
                  wallets: stub.wallets,
                  tags: stub.tags,
                ),
                digitsOf: (_) => 0,
                mainCurrency: 'VND',
                today: rows.first.occurredOn,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a row with a clock time leads its detail line with it', (
    tester,
  ) async {
    final stub = StubTransactionViewModel();
    final rows = stub.rows.take(2).toList();
    expect(rows.first.occurredTime, '12:40');
    expect(rows.last.occurredTime, isNull);
    await pump(tester, stub, rows);
    expect(find.text('12:40'), findsOneWidget);
    // Only the timed row shows a time; the detail line is unchanged.
    expect(find.textContaining(RegExp(r'\d\d:\d\d')), findsOneWidget);
    expect(find.text('Ăn uống · Tiền mặt'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('12:40')), findsWidgets);
  });

  testWidgets('a refunded row keeps the time and the refund note', (
    tester,
  ) async {
    final stub = StubTransactionViewModel();
    final rows = groupTransactionLegs([
      tx(
        'r',
        account: 'cash',
        amount: -300000,
        time: '09:05',
        category: 'food',
        merchant: 'Siêu thị',
        refunded: 100000,
      ),
    ]);
    await pump(tester, stub, rows);
    expect(find.text('09:05'), findsOneWidget);
    expect(find.textContaining('đã hoàn'), findsOneWidget);
  });
}
