import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/domain/overview.dart';
import 'package:mobile/features/home/domain/overview_summary.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import 'fixtures.dart';

void main() {
  group('balanceSummary', () {
    test('profile currency leads, others become pills, no conversion', () {
      final data = overview(
        net: [worth('USD', 125000), worth('VND', 48250000)],
        wallets: [
          wallet('a', 'A'),
          wallet('b', 'B'),
          wallet('usd', 'USD', currency: 'USD'),
        ],
      );
      final summary = balanceSummary(data, 'VND');
      expect(summary.main.currency, 'VND');
      expect(summary.main.minor, b(48250000));
      expect(summary.main.walletCount, 2);
      expect(summary.others.single.currency, 'USD');
      expect(summary.others.single.minor, b(125000));
      expect(summary.others.single.walletCount, 1);
    });

    test('currencies without an active wallet are left out', () {
      final data = overview(
        net: [worth('VND', 100), worth('EUR', 5)],
        wallets: [wallet('a', 'A')],
      );
      expect(balanceSummary(data, 'VND').others, isEmpty);
    });

    test('falls back to the first currency that has wallets', () {
      final data = overview(
        net: [worth('USD', 5)],
        wallets: [wallet('usd', 'USD', currency: 'USD')],
      );
      expect(balanceSummary(data, 'VND').main.currency, 'USD');
    });
  });

  test('monthFlow returns magnitudes and zero for a missing currency', () {
    final flow = monthFlow(month(), 'VND');
    expect(flow.income, b(18500000));
    expect(flow.expense, b(9320000));
    expect(monthFlow(month(), 'USD').isEmpty, isTrue);
  });

  group('spendingBreakdown', () {
    test('top 3 parents, the rest is Khác, percentages add up to 100', () {
      final result = spendingBreakdown(month(), 'VND', categories);
      expect(result.total, b(9320000));
      expect(result.slices.map((s) => s.name), [
        'Ăn uống',
        'Nhà ở',
        'Đi lại',
        null,
      ]);
      expect(result.slices.map((s) => s.percent), [38, 24, 18, 20]);
      expect(result.slices.fold(0, (a, s) => a + s.percent), 100);
    });

    test('rolls subcategories up to the parent', () {
      final flow = month(
        rows: [
          spend('pho', 300, parent: 'food'),
          spend('food', 100),
        ],
      );
      final result = spendingBreakdown(flow, 'VND', categories);
      expect(result.slices.single.name, 'Ăn uống');
      expect(result.slices.single.minor, b(400));
    });

    test('unnamed spending stays in Khác', () {
      final flow = month(rows: [spend('ghost', 900), spend('food', 100)]);
      final result = spendingBreakdown(flow, 'VND', categories);
      expect(result.slices.map((s) => s.name), ['Ăn uống', null]);
    });

    test('empty month has no slices', () {
      final result = spendingBreakdown(
        month(rows: const []),
        'VND',
        categories,
      );
      expect(result.slices, isEmpty);
      expect(result.total, BigInt.zero);
    });
  });

  group('credit cards', () {
    final today = DateTime(2026, 10, 21);

    test('used is the debt, level follows the limit ratio', () {
      final cards = creditCards([
        wallet(
          'ok',
          'A',
          type: WalletType.credit,
          balance: -6200000,
          limit: 20000000,
          dueDay: 5,
        ),
        wallet(
          'hi',
          'B',
          type: WalletType.credit,
          balance: -8000000,
          limit: 10000000,
        ),
        wallet(
          'max',
          'C',
          type: WalletType.credit,
          balance: -9500000,
          limit: 10000000,
        ),
        wallet('bank', 'D'),
      ], today);
      expect(cards, hasLength(3));
      expect(cards[0].used, b(6200000));
      expect(cards[0].level, CreditLevel.normal);
      expect(cards[1].level, CreditLevel.high);
      expect(cards[2].level, CreditLevel.critical);
    });

    test('next due date rolls to next month and clamps to month end', () {
      expect(nextDueDate(25, today), DateTime(2026, 10, 25));
      expect(nextDueDate(5, today), DateTime(2026, 11, 5));
      expect(nextDueDate(31, DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
      expect(nextDueDate(null, today), isNull);
    });

    test('due within 7 days', () {
      final card = creditCards([
        wallet('c', 'C', type: WalletType.credit, dueDay: 25),
      ], today).single;
      expect(card.dueWithin(today, 7), isTrue);
      expect(card.dueWithin(DateTime(2026, 10, 10), 7), isFalse);
    });
  });

  test('other currency spending skips the main currency and zeros', () {
    final flow = month(
      extra: [
        CashflowTotal(
          currency: 'USD',
          incomeMinor: BigInt.zero,
          expenseMinor: b(-3500),
          netMinor: b(-3500),
        ),
        CashflowTotal(
          currency: 'EUR',
          incomeMinor: b(5),
          expenseMinor: BigInt.zero,
          netMinor: b(5),
        ),
      ],
    );
    expect(otherCurrencySpending(flow, 'VND').map((r) => r.currency), ['USD']);
  });
}
