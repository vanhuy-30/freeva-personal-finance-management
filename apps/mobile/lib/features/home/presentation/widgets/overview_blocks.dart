import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_detail_sheet.dart';
import '../../domain/overview.dart';
import '../../domain/overview_summary.dart';
import '../viewmodels/home_view_model.dart';
import 'overview_tiles.dart';
import 'new_month_review_card.dart';
import 'recent_row_data.dart';
import 'recent_transactions.dart';
import '../../../insights/presentation/widgets/overview_insight_slot.dart';

/// Blocks under the quick actions once data is loaded (PA 3): the tile grid,
/// last-month review (new month only), the "Đáng chú ý" card (S.1) and
/// "Gần đây".
class OverviewBlocks extends StatelessWidget {
  const OverviewBlocks({required this.model, required this.data, super.key});

  /// Space between Overview blocks.
  static const double gap = 22;

  final HomeViewModel model;
  final OverviewData data;

  String _monthLabel(BuildContext context, String from) => DateFormat(
    S.of(context).homeMonthPattern,
    Localizations.localeOf(context).toString(),
  ).format(DateTime.parse(from));

  void _open(BuildContext context, TransactionBundle row) {
    final transactions = getIt<TransactionViewModel>();
    if (!transactions.composerReady) transactions.load();
    openTransactionDetail(context, transactions, row);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final main = balanceSummary(data, model.currency).main.currency;
    final digits = data.digitsOf;
    final previous = data.previousMonth;
    final names = RecentRowNames(s, data.categories, data.wallets);
    final rows = [
      for (final item in model.pending)
        names.fromQueued(item, s.homePendingSync),
      for (final row in data.recent) names.fromBundle(row),
    ].take(3).toList();
    const gap = SizedBox(height: OverviewBlocks.gap);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverviewTiles(data: data, currency: main),
        gap,
        if (previous != null && !monthFlow(previous, main).isEmpty) ...[
          NewMonthReviewCard(
            monthLabel: _monthLabel(context, previous.period.from),
            on: previous.period.from,
            flow: monthFlow(previous, main),
            minorDigits: digits(main),
            insight: monthInsight(
              previous: previous,
              before: data.monthBefore,
              budget: data.previousBudget,
              currency: main,
              categories: data.categories,
            ),
          ),
          // Board S.1: 14 under the review card.
          const OverviewInsightSlot(top: 14, bottom: 0),
          gap,
        ] else
          const OverviewInsightSlot(top: 0, bottom: OverviewBlocks.gap),
        RecentTransactions(
          rows: rows,
          digitsOf: digits,
          onOpen: (row) => _open(context, row),
        ),
      ],
    );
  }
}
