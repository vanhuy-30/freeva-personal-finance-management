import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/empty_state.dart';
import '../viewmodels/transaction_results_view_model.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_day_list.dart';
import 'transaction_detail_sheet.dart';
import 'transaction_naming.dart';
import 'transaction_summary_line.dart';

/// Search results: prompt, no-result, or count + totals + marked rows.
class SearchResultsBody extends StatelessWidget {
  const SearchResultsBody({
    required this.main,
    required this.results,
    super.key,
  });

  final TransactionViewModel main;
  final TransactionResultsViewModel results;

  int _digits(String code) =>
      main.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final text = results.filter.search?.trim() ?? '';
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, 0, margin, FreevaSpace.s8),
      children: [
        if (text.isEmpty)
          Text(
            s.txSearchPrompt,
            style: FreevaTypography.bodyS.copyWith(
              color: context.colors.textSecondary,
            ),
          )
        else if (!results.loading && results.rows.isEmpty)
          EmptyState(title: s.txNoResultTitle, message: s.txNoResultBody)
        else ...[
          TransactionSummaryLine(
            summary: results.summary,
            mainCurrency: main.profileCurrency,
            digitsOf: _digits,
            count: true,
          ),
          const SizedBox(height: FreevaSpace.s4),
          TransactionDayList(
            rows: results.rows,
            naming: TransactionNaming(
              s,
              categories: main.categories,
              wallets: main.wallets,
              tags: main.tags,
            ),
            digitsOf: _digits,
            mainCurrency: main.profileCurrency,
            today: main.today() ?? '',
            highlight: text,
            onOpen: (row) async {
              await openTransactionDetail(context, main, row);
              await results.reload();
            },
          ),
        ],
      ],
    );
  }
}
