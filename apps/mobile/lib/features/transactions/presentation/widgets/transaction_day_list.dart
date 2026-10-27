import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../sync/presentation/widgets/sync_mark_chip.dart';
import '../../domain/transaction.dart';
import 'transaction_day_header.dart';
import 'transaction_list_row.dart';
import 'saved_row_flash.dart';
import 'transaction_naming.dart';

/// Transactions grouped by day: a header with the day's net (transfers
/// excluded) and a white card of rows.
class TransactionDayList extends StatelessWidget {
  const TransactionDayList({
    required this.rows,
    required this.naming,
    required this.digitsOf,
    required this.mainCurrency,
    required this.today,
    required this.onOpen,
    this.highlight,
    this.trailingFor,
    this.markFor,
    this.muted = false,
    this.highlightId,
    this.showNet = true,
    super.key,
  });

  final List<TransactionBundle> rows;
  final TransactionNaming naming;
  final int Function(String) digitsOf;
  final String mainCurrency;

  /// `yyyy-MM-dd`, for "Hôm nay".
  final String today;
  final ValueChanged<TransactionBundle> onOpen;
  final String? highlight;
  final Widget Function(TransactionBundle)? trailingFor;

  /// Queued change of a row, shown as a chip or clock.
  final SyncMark? Function(TransactionBundle)? markFor;

  /// Deleted list: amounts muted.
  final bool muted;

  /// Row to mark as just saved.
  final String? highlightId;

  /// Day net in the header; search and deleted lists show only the day.
  final bool showNet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const radius = Radius.circular(FreevaComponent.listRadius);
    final days = <String, List<TransactionBundle>>{};
    for (final row in rows) {
      days.putIfAbsent(row.occurredOn, () => []).add(row);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: day, value: items) in days.entries) ...[
          TransactionDayHeader(
            date: day,
            today: today,
            rows: items,
            mainCurrency: mainCurrency,
            digitsOf: digitsOf,
            showNet: showNet,
          ),
          FreevaCard(
            list: true,
            padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s1),
            child: Column(
              children: [
                for (final (i, row) in items.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: FreevaSpace.s4,
                      endIndent: rowPadding.right,
                      color: c.listDivider,
                    ),
                  if (row.id == highlightId)
                    SavedRowFlash(
                      key: ValueKey(row.id),
                      borderRadius: BorderRadius.vertical(
                        top: i == 0 ? radius : Radius.zero,
                        bottom: i == items.length - 1 ? radius : Radius.zero,
                      ),
                      builder: (t) => _row(
                        row,
                        // White circle while the mark is visible.
                        iconBg: t > .25 ? c.bgSurface : null,
                      ),
                    )
                  else
                    _row(row),
                ],
              ],
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
        ],
      ],
    );
  }

  /// Board card padding: 16 on the left, 12 on the right when a restore
  /// button ends the row, else 16.
  EdgeInsets get rowPadding => EdgeInsets.only(
    left: FreevaSpace.s4,
    right: trailingFor != null ? FreevaSpace.s3 : FreevaSpace.s4,
  );

  Widget _row(TransactionBundle row, {Color? iconBg}) => Padding(
    padding: rowPadding,
    child: TransactionListRow(
      row: row,
      iconBg: iconBg,
      label: naming.label(row),
      digits: digitsOf(row.legs.first.currencyCode),
      showCurrency: row.legs.first.currencyCode != mainCurrency,
      highlight: highlight,
      muted: muted,
      onTap: () => onOpen(row),
      trailing: trailingFor?.call(row),
      mark: markFor?.call(row),
    ),
  );
}
