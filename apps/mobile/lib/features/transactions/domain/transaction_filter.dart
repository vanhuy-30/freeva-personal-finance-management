import '../../categories/domain/finance_category.dart';
import 'transaction.dart';

enum PeriodPreset { thisWeek, thisMonth, lastMonth, custom, allTime }

/// Inclusive calendar range `yyyy-MM-dd`.
class DateRange {
  const DateRange(this.from, this.to);
  final String from;
  final String to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(from, to);
}

/// What the transaction list shows. Immutable; the list default is "this
/// month, every type"; search starts from "all time".
class TransactionFilter {
  const TransactionFilter({
    this.type,
    this.period = PeriodPreset.thisMonth,
    this.custom,
    this.accountIds = const {},
    this.categoryIds = const {},
    this.tagIds = const {},
    this.search,
  });

  static const list = TransactionFilter();
  static const searching = TransactionFilter(period: PeriodPreset.allTime);

  final TransactionType? type;
  final PeriodPreset period;
  final DateRange? custom;
  final Set<String> accountIds;

  /// Chosen categories; a parent also matches its children (see [toQuery]).
  final Set<String> categoryIds;
  final Set<String> tagIds;
  final String? search;

  static const _keep = Object();

  TransactionFilter copyWith({
    Object? type = _keep,
    PeriodPreset? period,
    Object? custom = _keep,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<String>? tagIds,
    Object? search = _keep,
  }) => TransactionFilter(
    type: identical(type, _keep) ? this.type : type as TransactionType?,
    period: period ?? this.period,
    custom: identical(custom, _keep) ? this.custom : custom as DateRange?,
    accountIds: accountIds ?? this.accountIds,
    categoryIds: categoryIds ?? this.categoryIds,
    tagIds: tagIds ?? this.tagIds,
    search: identical(search, _keep) ? this.search : search as String?,
  );

  /// Conditions shown as removable chips (period counts when not the base).
  bool get narrowed =>
      accountIds.isNotEmpty || categoryIds.isNotEmpty || tagIds.isNotEmpty;

  /// Resets everything except the search text and the base period.
  TransactionFilter cleared(PeriodPreset base) =>
      TransactionFilter(period: base, search: search);

  TransactionQuery toQuery({
    required String today,
    required int fiscalDay,
    required List<FinanceCategory> categories,
    int page = 1,
    int pageSize = 50,
    bool deleted = false,
  }) {
    final range = rangeFor(period, today, fiscalDay, custom);
    final text = search?.trim();
    return TransactionQuery(
      page: page,
      pageSize: pageSize,
      deleted: deleted,
      type: type,
      search: text == null || text.isEmpty ? null : text,
      from: range?.from,
      to: range?.to,
      accountIds: accountIds.toList()..sort(),
      categoryIds: withChildren(categoryIds, categories),
      tagIds: tagIds.toList()..sort(),
    );
  }
}

/// A chosen parent also selects its children.
List<String> withChildren(Set<String> ids, List<FinanceCategory> categories) {
  final all = {...ids};
  for (final category in categories) {
    if (category.parentId != null && ids.contains(category.parentId)) {
      all.add(category.id);
    }
  }
  return all.toList()..sort();
}

/// Date range of a preset. Week is Monday–Sunday; a month starts on the
/// profile's fiscal day (1–28). All time and an unset custom range are null.
DateRange? rangeFor(
  PeriodPreset period,
  String today,
  int fiscalDay,
  DateRange? custom,
) {
  final day = DateTime.utc(
    int.parse(today.substring(0, 4)),
    int.parse(today.substring(5, 7)),
    int.parse(today.substring(8, 10)),
  );
  DateRange month(int offset) {
    var start = DateTime.utc(day.year, day.month, fiscalDay);
    if (day.day < fiscalDay) {
      start = DateTime.utc(day.year, day.month - 1, fiscalDay);
    }
    start = DateTime.utc(start.year, start.month + offset, fiscalDay);
    final end = DateTime.utc(
      start.year,
      start.month + 1,
      fiscalDay,
    ).subtract(const Duration(days: 1));
    return DateRange(_date(start), _date(end));
  }

  return switch (period) {
    PeriodPreset.thisWeek => DateRange(
      _date(day.subtract(Duration(days: day.weekday - 1))),
      _date(day.add(Duration(days: 7 - day.weekday))),
    ),
    PeriodPreset.thisMonth => month(0),
    PeriodPreset.lastMonth => month(-1),
    PeriodPreset.custom => custom,
    PeriodPreset.allTime => null,
  };
}

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
