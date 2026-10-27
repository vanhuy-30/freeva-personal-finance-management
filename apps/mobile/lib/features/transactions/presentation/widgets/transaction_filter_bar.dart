import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_filter.dart';
import 'active_filter_chip.dart';

/// Type chips and the period chip (opens the filter sheet). Once a wallet,
/// category or tag condition is on, only ink chips with × for each active
/// condition (period first; its chip opens the sheet).
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
    final chips = <Widget>[
      if (filter.narrowed) ...[
        // TxNoResult: once a condition is on, the row shows only the
        // active conditions as ink chips, the period first.
        ActiveFilterChip(
          label: filter.period == PeriodPreset.thisMonth
              ? s.txPeriodThisMonth
              : periodLabel(s, filter, range, locale),
          semanticsLabel: s.txFilterPeriod,
          onRemove: onOpenSheet,
        ),
        if (filter.type case final type?)
          ActiveFilterChip(
            label: switch (type) {
              TransactionType.expense => s.transactionExpense,
              TransactionType.income => s.transactionIncome,
              TransactionType.transfer => s.transactionTransfer,
            },
            onRemove: () => onChanged(filter.copyWith(type: null)),
          ),
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
      ] else ...[
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
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }
}
