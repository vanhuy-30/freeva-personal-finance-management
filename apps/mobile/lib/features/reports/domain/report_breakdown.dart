import 'report.dart';

enum BreakdownKind { expense, income }

/// A category (rolled up to its parent) or the "Khác" remainder when [id] and
/// [name] are null.
class BreakdownSlice {
  const BreakdownSlice({
    required this.id,
    required this.name,
    required this.minor,
    required this.percent,
    required this.categoryCount,
    required this.transactionCount,
  });

  final String? id;
  final String? name;
  final BigInt minor;
  final int percent;

  /// Parent categories folded into a "Khác" slice (1 for a named one).
  final int categoryCount;
  final int transactionCount;

  bool get isOther => name == null;
}

class Breakdown {
  const Breakdown({required this.total, required this.slices});

  final BigInt total;

  /// Top [reportBreakdownTop] by amount, then "Khác". Empty when [total] is 0.
  final List<BreakdownSlice> slices;
}

const reportBreakdownTop = 3;

/// Rolls leaf categories up to parents for [currency] (names come with the
/// rows). Uncategorised income joins "Khác". Percentages add up to exactly 100.
Breakdown reportBreakdown(
  CashflowReport report,
  String currency,
  BreakdownKind kind,
) {
  final names = <String?, String?>{};
  final amounts = <String?, BigInt>{};
  final counts = <String?, int>{};
  for (final row in report.byCategory) {
    final minor = kind == BreakdownKind.expense
        ? row.expenseMinor
        : row.incomeMinor;
    if (row.currency != currency || minor == BigInt.zero) continue;
    final key = row.parentId ?? row.categoryId;
    names[key] = row.parentId == null ? row.name : row.parentName;
    amounts.update(key, (v) => v + minor.abs(), ifAbsent: () => minor.abs());
    counts.update(
      key,
      (v) => v + row.transactionCount,
      ifAbsent: () => row.transactionCount,
    );
  }
  final total = amounts.values.fold(BigInt.zero, (a, b) => a + b);
  if (total == BigInt.zero) return Breakdown(total: total, slices: const []);
  final ranked = amounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final head = [
    for (final e in ranked)
      if (names[e.key] != null) e,
  ].take(reportBreakdownTop).toList();
  final rest = [
    for (final e in ranked)
      if (!head.contains(e)) e,
  ];
  final restMinor = rest.fold(BigInt.zero, (a, e) => a + e.value);
  final restCount = rest.fold(0, (a, e) => a + (counts[e.key] ?? 0));
  final parts = [
    for (final e in head) (e.key, names[e.key], e.value, 1, counts[e.key] ?? 0),
    if (restMinor > BigInt.zero)
      (null, null, restMinor, rest.length, restCount),
  ];
  final percents = _wholePercents([for (final p in parts) p.$3], total);
  return Breakdown(
    total: total,
    slices: [
      for (var i = 0; i < parts.length; i++)
        BreakdownSlice(
          id: parts[i].$1,
          name: parts[i].$2,
          minor: parts[i].$3,
          percent: percents[i],
          categoryCount: parts[i].$4,
          transactionCount: parts[i].$5,
        ),
    ],
  );
}

/// Largest-remainder rounding so the shown percentages sum to exactly 100.
List<int> _wholePercents(List<BigInt> parts, BigInt total) {
  final scaled = [for (final p in parts) p * BigInt.from(100)];
  final floors = [for (final s in scaled) (s ~/ total).toInt()];
  final order = [for (var i = 0; i < parts.length; i++) (i, scaled[i] % total)]
    ..sort((a, b) => b.$2.compareTo(a.$2));
  var missing = 100 - floors.fold(0, (a, b) => a + b);
  for (final (index, _) in order) {
    if (missing <= 0) break;
    floors[index]++;
    missing--;
  }
  return floors;
}
