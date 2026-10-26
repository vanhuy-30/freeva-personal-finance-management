import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/sync/presentation/widgets/sync_mark_chip.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_day_list.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';

import '../transactions/c1_stub.dart';

void main() {
  testWidgets('rows carry the chip or the clock and say it aloud', (
    tester,
  ) async {
    final stub = StubTransactionViewModel();
    final rows = stub.rows.take(2).toList();
    late S s;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) {
            s = S.of(context);
            return Scaffold(
              body: SingleChildScrollView(
                child: TransactionDayList(
                  rows: rows,
                  naming: TransactionNaming(
                    s,
                    categories: stub.categories,
                    wallets: stub.wallets,
                    tags: stub.tags,
                  ),
                  digitsOf: (_) => 0,
                  mainCurrency: 'VND',
                  today: rows.first.occurredOn,
                  onOpen: (_) {},
                  markFor: (row) => row.id == rows.first.id
                      ? SyncMark.review
                      : SyncMark.waiting,
                ),
              ),
            );
          },
        ),
      ),
    );
    expect(find.text('Cần xem lại'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Chờ đồng bộ')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'Cần xem lại$')), findsWidgets);
  });
}
