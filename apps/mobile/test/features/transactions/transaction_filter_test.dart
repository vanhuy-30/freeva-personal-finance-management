import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_filter.dart';

void main() {
  group('rangeFor', () {
    test('week runs Monday to Sunday', () {
      // 2026-10-21 is a Wednesday.
      expect(
        rangeFor(PeriodPreset.thisWeek, '2026-10-21', 1, null),
        const DateRange('2026-10-19', '2026-10-25'),
      );
    });

    test('month follows the profile start day', () {
      expect(
        rangeFor(PeriodPreset.thisMonth, '2026-10-21', 1, null),
        const DateRange('2026-10-01', '2026-10-31'),
      );
      expect(
        rangeFor(PeriodPreset.thisMonth, '2026-10-21', 25, null),
        const DateRange('2026-09-25', '2026-10-24'),
      );
      expect(
        rangeFor(PeriodPreset.thisMonth, '2026-10-25', 25, null),
        const DateRange('2026-10-25', '2026-11-24'),
      );
      expect(
        rangeFor(PeriodPreset.lastMonth, '2026-01-10', 1, null),
        const DateRange('2025-12-01', '2025-12-31'),
      );
    });

    test('all time and an unset custom range have no dates', () {
      expect(rangeFor(PeriodPreset.allTime, '2026-10-21', 1, null), isNull);
      expect(rangeFor(PeriodPreset.custom, '2026-10-21', 1, null), isNull);
      const custom = DateRange('2026-10-01', '2026-10-05');
      expect(rangeFor(PeriodPreset.custom, '2026-10-21', 1, custom), custom);
    });
  });

  test('a chosen parent category also selects its children', () {
    const categories = [
      FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null),
      FinanceCategory(id: 'pho', name: 'Phở', parentId: 'food'),
      FinanceCategory(id: 'bus', name: 'Đi lại', parentId: null),
    ];
    expect(withChildren({'food'}, categories), ['food', 'pho']);
  });

  test('toQuery carries every condition and trims search', () {
    const filter = TransactionFilter(
      type: TransactionType.expense,
      accountIds: {'b', 'a'},
      tagIds: {'t'},
      search: '  phở ',
    );
    final query = filter.toQuery(
      today: '2026-10-21',
      fiscalDay: 1,
      categories: const [],
      pageSize: 1,
    );
    expect(query.type, TransactionType.expense);
    expect(query.from, '2026-10-01');
    expect(query.to, '2026-10-31');
    expect(query.accountIds, ['a', 'b']);
    expect(query.tagIds, ['t']);
    expect(query.search, 'phở');
    expect(query.pageSize, 1);
  });

  test('narrowed and cleared', () {
    const filter = TransactionFilter(accountIds: {'a'}, search: 'x');
    expect(filter.narrowed, isTrue);
    final cleared = filter.cleared(PeriodPreset.thisMonth);
    expect(cleared.narrowed, isFalse);
    expect(cleared.search, 'x');
    expect(TransactionFilter.list.narrowed, isFalse);
  });
}
