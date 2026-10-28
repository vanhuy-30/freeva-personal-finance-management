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
import 'credit_cards_block.dart';
import 'new_month_review_card.dart';
import 'recent_row_data.dart';
import 'recent_transactions.dart';
import 'spending_block.dart';

/// Blocks under the quick actions once data is loaded: credit cards first
/// for the debt goal, "Chi tháng", last-month review (new month only), credit
/// cards (other goals), "Gần đây".
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
    final today = data.loadedAt;
    final cards = creditCards(data.wallets, today);
    final previous = data.previousMonth;
    final names = RecentRowNames(s, data.categories, data.wallets);
    final rows = [
      for (final item in model.pending)
        names.fromQueued(item, s.homePendingSync),
      for (final row in data.recent) names.fromBundle(row),
    ].take(3).toList();
    const gap = SizedBox(height: OverviewBlocks.gap);
    final credit = cards.isEmpty
        ? null
        : CreditCardsBlock(cards: cards, today: today, digitsOf: digits);
    final debtFirst = credit != null && model.debtGoal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (debtFirst) ...[credit, gap],
        SpendingBlock(
          breakdown: spendingBreakdown(data.month, main, data.categories),
          currency: main,
          minorDigits: digits(main),
          monthLabel: _monthLabel(context, data.month.period.from),
          otherCurrencies: otherCurrencySpending(data.month, main),
          digitsOf: digits,
          budget: data.budget,
        ),
        gap,
        if (previous != null && !monthFlow(previous, main).isEmpty) ...[
          NewMonthReviewCard(
            monthLabel: _monthLabel(context, previous.period.from),
            flow: monthFlow(previous, main),
            minorDigits: digits(main),
          ),
          gap,
        ],
        if (credit != null && !debtFirst) ...[credit, gap],
        RecentTransactions(
          rows: rows,
          digitsOf: digits,
          onOpen: (row) => _open(context, row),
        ),
      ],
    );
  }
}
