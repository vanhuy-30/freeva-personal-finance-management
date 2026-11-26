import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../home/presentation/widgets/recent_row_data.dart';
import '../../../settings/presentation/widgets/choice_sheet.dart';
import '../../../transactions/domain/transaction.dart';
import '../viewmodels/category_report_view_model.dart';

/// "Giao dịch" of one slice: a sort icon, ten rows at a time and "Xem thêm".
class CategoryTransactions extends StatelessWidget {
  const CategoryTransactions({
    required this.model,
    required this.names,
    required this.digitsOf,
    required this.onOpen,
    super.key,
  });

  final CategoryReportViewModel model;
  final RecentRowNames names;
  final int Function(String) digitsOf;
  final ValueChanged<TransactionBundle> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: FreevaSpace.s1),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.reportTransactions,
                    style: FreevaTypography.titleM.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              FreevaIconButton(
                icon: LucideIcons.arrowUpDown,
                label: s.reportSortLabel,
                kind: FreevaIconButtonKind.subtle,
                onPressed: () => _pickSort(context, s),
              ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        if (model.failure != null && model.items.isEmpty)
          ErrorRetry(
            title: s.reportLargestError,
            message: s.homeErrorBody,
            onRetry: model.load,
          )
        else if (model.loading && model.items.isEmpty)
          const SkeletonRows(count: 3)
        else ...[
          FreevaCard(
            list: true,
            padding: const EdgeInsets.symmetric(
              horizontal: FreevaSpace.s4,
              vertical: FreevaSpace.s1,
            ),
            child: Column(
              children: [
                for (final (i, bundle) in model.items.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.listDivider),
                  _row(context, s, locale, bundle),
                ],
              ],
            ),
          ),
          if (model.hasMore) ...[
            const SizedBox(height: FreevaSpace.s2),
            Center(
              child: FreevaButton(
                label: s.reportLoadMore,
                variant: FreevaButtonVariant.link,
                loading: model.loadingMore,
                onPressed: model.loadMore,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _pickSort(BuildContext context, S s) async {
    final picked = await showChoiceSheet<TransactionSort>(
      context,
      title: s.reportSortLabel,
      selected: model.sort,
      options: [
        Choice(TransactionSort.date, s.reportSortNewest),
        Choice(TransactionSort.dateAsc, s.reportSortOldest),
        Choice(TransactionSort.amountDesc, s.reportSortLargest),
        Choice(TransactionSort.amountAsc, s.reportSortSmallest),
      ],
    );
    if (picked != null) unawaited(model.setSort(picked));
  }

  Widget _row(BuildContext context, S s, String locale, TransactionBundle b) {
    final row = names.fromBundle(b);
    // Every row is in the same slice and period: "Đi chợ · 19/10".
    final detail = [
      names.category(b.type, b.categoryId),
      DateFormat(
        s.reportShortDatePattern,
        locale,
      ).format(DateTime.parse(b.occurredOn)),
    ].join(' · ');
    return TransactionRow(
      icon: row.icon,
      title: row.title,
      subtitle: detail,
      tone: row.tone,
      semanticsLabel: spoken(s, row, digitsOf(row.currency), locale),
      onTap: () => onOpen(b),
      amount: MoneyDisplay(
        minor: row.minor,
        currency: row.currency,
        minorDigits: digitsOf(row.currency),
        tone: row.tone,
        style: FreevaTypography.titleM,
        showCurrency: false,
      ),
    );
  }
}
