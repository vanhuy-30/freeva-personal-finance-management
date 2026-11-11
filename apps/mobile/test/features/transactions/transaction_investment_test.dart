import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_labels.dart';
import 'package:mobile/features/transactions/presentation/widgets/transaction_naming.dart';
import 'package:mobile/core/widgets/money_display.dart';

import '../home/fixtures.dart' show b;

TxLeg _leg(BigInt amount) => TxLeg(
  id: 'i1',
  clientId: 'i1',
  accountId: 'w1',
  currencyCode: 'VND',
  amountMinor: amount,
  type: TransactionType.investment,
  occurredOn: '2026-11-06',
  categoryId: null,
  notes: null,
  merchant: null,
  tagIds: const [],
  transferGroupId: null,
  deletedAt: null,
  version: 1,
  createdAt: DateTime.utc(2026, 11, 6),
);

void main() {
  testWidgets('an investment leg is a known type with its own wording', (
    tester,
  ) async {
    expect(
      TransactionType.values.byName('investment'),
      TransactionType.investment,
    );
    late S s;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Builder(
          builder: (context) {
            s = S.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(transactionTypeLabel(s, TransactionType.investment), 'Đầu tư');
    final naming = TransactionNaming(
      s,
      categories: const [],
      wallets: const [],
    );
    final buy = naming.label(TransactionBundle(legs: [_leg(-b(35000000))]));
    expect(buy.title, 'Đầu tư');
    expect(buy.minor, b(35000000));
    // Money out of the wallet keeps its sign: it moved the balance down.
    expect(buy.tone, MoneyTone.expense);
    final sell = naming.label(TransactionBundle(legs: [_leg(b(24000000))]));
    expect(sell.tone, MoneyTone.income);
  });
}
