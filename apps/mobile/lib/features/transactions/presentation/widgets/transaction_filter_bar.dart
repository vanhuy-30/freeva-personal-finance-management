import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_filter.dart';
import 'active_filter_chip.dart';

/// Type chips, the period chip (opens the filter sheet) and one ink chip
/// with × per extra condition (wallet, category, tag).
class TransactionFilterBar extends StatelessWidget {
  const TransactionFilterBar({
    required this.filter,
    required this.range,
    required this.names,
    required this.onChanged,
    required this.onOpenSheet,
    super.key,
  });

  final TransactionFilter filter;

  /// Resolved dates of the current period, for the chip label.
  final DateRange? range;

  /// Display name per wallet / category / tag id.
  final String Function(String id) names;
  final ValueChanged<TransactionFilter> onChanged;
  final VoidCallback onOpenSheet;

  static String periodLabel(
    S s,
    TransactionFilter f,
    DateRange? range,
    String locale,
  ) {
    String short(String d) =>
        DateFormat('dd/MM', locale).format(DateTime.parse(d));
    return switch (f.period) {
      PeriodPreset.thisWeek => s.txPeriodThisWeek,
      PeriodPreset.thisMonth when range != null => s.txMonthChip(
        DateFormat(s.homeMonthPattern, locale).format(DateTime.parse(range.to)),
      ),
      PeriodPreset.thisMonth => s.txPeriodThisMonth,
      PeriodPreset.lastMonth => s.txPeriodLastMonth,
      PeriodPreset.custom when range != null => s.txRangeChip(
        short(range.from),
        short(range.to),
      ),
      PeriodPreset.custom => s.txPeriodCustom,
      PeriodPreset.allTime => s.txPeriodAllTime,
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    Widget type(String label, TransactionType? value) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FreevaChip(
        label: label,
        kind: FreevaChipKind.filter,
        selected: filter.type == value,
        onTap: () => onChanged(filter.copyWith(type: value)),
      ),
    );
    Widget active(
      String id,
      Set<String> Function(TransactionFilter) pick,
      TransactionFilter Function(Set<String>) put,
    ) => ActiveFilterChip(
      label: names(id),
      onRemove: () => onChanged(put({...pick(filter)}..remove(id))),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        // Active conditions come first so they are visible without
        // scrolling (C1.4); then type chips and the period chip.
        children: [
          for (final id in filter.accountIds)
            active(
              id,
              (f) => f.accountIds,
              (v) => filter.copyWith(accountIds: v),
            ),
          for (final id in filter.categoryIds)
            active(
              id,
              (f) => f.categoryIds,
              (v) => filter.copyWith(categoryIds: v),
            ),
          for (final id in filter.tagIds)
            active(id, (f) => f.tagIds, (v) => filter.copyWith(tagIds: v)),
          type(s.transactionAll, null),
          type(s.transactionExpense, TransactionType.expense),
          type(s.transactionIncome, TransactionType.income),
          type(s.transactionTransfer, TransactionType.transfer),
          FreevaChip(
            label: periodLabel(s, filter, range, locale),
            kind: FreevaChipKind.filter,
            selected: false,
            trailingIcon: LucideIcons.chevronDown,
            onTap: onOpenSheet,
          ),
        ],
      ),
    );
  }
}
