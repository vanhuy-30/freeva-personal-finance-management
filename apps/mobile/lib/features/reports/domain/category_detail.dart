import 'report.dart';
import 'report_breakdown.dart';

/// Everything the category detail screen needs from the report in hand.
class CategoryDetailArgs {
  const CategoryDetailArgs({
    required this.report,
    required this.currency,
    required this.digits,
    required this.kind,
    required this.slice,
  });

  final CashflowReport report;
  final String currency;
  final int digits;
  final BreakdownKind kind;
  final BreakdownSlice slice;

  /// Every leaf category behind the slice, for the transaction filter.
  /// Null when part of it is uncategorised income, which the API cannot
  /// filter for.
  List<String>? get categoryIds {
    final ids = <String>{};
    for (final row in _rows(report, currency, kind, slice.memberIds)) {
      final id = row.categoryId;
      if (id == null) return null;
      ids.add(id);
    }
    return ids.toList()..sort();
  }
}

class CategoryBar {
  const CategoryBar({
    required this.name,
    required this.minor,
    required this.general,
  });

  final String name;
  final BigInt minor;

  /// The parent's own transactions, shown as "Ăn uống (chung)" when it also
  /// has children.
  final bool general;
}

class CategoryDetail {
  const CategoryDetail({
    required this.total,
    required this.percent,
    required this.bars,
  });

  final BigInt total;

  /// Whole-number share of everything of this kind in the period.
  final int percent;
  final List<CategoryBar> bars;
}

CategoryDetail categoryDetail(CategoryDetailArgs args) {
  final rows = _rows(
    args.report,
    args.currency,
    args.kind,
    args.slice.memberIds,
  );
  BigInt minor(CashflowCategoryRow row) =>
      (args.kind == BreakdownKind.expense ? row.expenseMinor : row.incomeMinor)
          .abs();
  final total = rows.fold(BigInt.zero, (sum, row) => sum + minor(row));
  final all = args.report.byCategory
      .where((row) => row.currency == args.currency)
      .fold(BigInt.zero, (sum, row) => sum + minor(row));
  final percent = all == BigInt.zero
      ? 0
      : ((total * BigInt.from(100) * BigInt.two + all) ~/ (all * BigInt.two))
            .toInt();
  final single = args.slice.memberIds.length == 1;
  final bars = <CategoryBar>[];
  if (single) {
    final hasChildren = rows.any((row) => row.parentId != null);
    for (final row in rows) {
      bars.add(
        CategoryBar(
          name: row.name ?? '',
          minor: minor(row),
          general: row.parentId == null && hasChildren,
        ),
      );
    }
  } else {
    final byMember = <String?, BigInt>{};
    final names = <String?, String>{};
    for (final row in rows) {
      final key = row.parentId ?? row.categoryId;
      byMember.update(key, (v) => v + minor(row), ifAbsent: () => minor(row));
      names[key] = (row.parentId == null ? row.name : row.parentName) ?? '';
    }
    for (final e in byMember.entries) {
      bars.add(
        CategoryBar(name: names[e.key]!, minor: e.value, general: false),
      );
    }
  }
  bars.sort((a, b) => b.minor.compareTo(a.minor));
  return CategoryDetail(total: total, percent: percent, bars: bars);
}

Iterable<CashflowCategoryRow> _rows(
  CashflowReport report,
  String currency,
  BreakdownKind kind,
  List<String?> members,
) => report.byCategory.where((row) {
  final minor = kind == BreakdownKind.expense
      ? row.expenseMinor
      : row.incomeMinor;
  return row.currency == currency &&
      minor != BigInt.zero &&
      members.contains(row.parentId ?? row.categoryId);
});
