import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/error_retry.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../home/presentation/widgets/recent_row_data.dart';
import '../../../transactions/domain/transaction.dart';
import '../viewmodels/category_report_view_model.dart';

/// "Giao dịch lớn nhất": the top three and "Xem cả N" for the filtered list.
class LargestTransactions extends StatelessWidget {
  const LargestTransactions({
    required this.model,
    required this.names,
    required this.digitsOf,
    required this.onOpen,
    required this.onSeeAll,
    super.key,
  });

  final CategoryReportViewModel model;
  final RecentRowNames names;
  final int Function(String) digitsOf;
  final ValueChanged<TransactionBundle> onOpen;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final count = model.count;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    s.reportLargest,
                    style: FreevaTypography.titleM.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              if (count != null && count > 0)
                FreevaButton(
                  label: s.reportSeeAll(count),
                  variant: FreevaButtonVariant.link,
                  onPressed: onSeeAll,
                ),
            ],
          ),
        ),
        const SizedBox(height: FreevaSpace.s2),
        if (model.failure != null && model.largest.isEmpty)
          ErrorRetry(
            title: s.reportLargestError,
            message: s.homeErrorBody,
            onRetry: model.load,
          )
        else if (model.loading && model.largest.isEmpty)
          const SkeletonRows(count: 3)
        else
          FreevaCard(
            list: true,
            padding: const EdgeInsets.symmetric(
              horizontal: FreevaSpace.s4,
              vertical: FreevaSpace.s1,
            ),
            child: Column(
              children: [
                for (final (i, bundle) in model.largest.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.listDivider),
                  _row(context, s, locale, bundle),
                ],
              ],
            ),
          ),
      ],
    );
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
