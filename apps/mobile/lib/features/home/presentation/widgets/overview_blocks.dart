import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../transactions/presentation/widgets/transaction_editor.dart';
import '../../domain/overview.dart';
import '../../domain/overview_summary.dart';
import '../viewmodels/home_view_model.dart';
import 'credit_cards_block.dart';
import 'new_month_review_card.dart';
import 'recent_row_data.dart';
import 'recent_transactions.dart';
import 'spending_block.dart';

/// Blocks under the quick actions once data is loaded: credit cards (when
/// the user has a credit wallet), last-month review (new month only),
/// "Chi tháng", "Gần đây".
class OverviewBlocks extends StatelessWidget {
  const OverviewBlocks({required this.model, required this.data, super.key});

  final HomeViewModel model;
  final OverviewData data;

  String _monthLabel(BuildContext context, String from) => DateFormat(
    S.of(context).homeMonthPattern,
    Localizations.localeOf(context).toString(),
  ).format(DateTime.parse(from));

  void _open(BuildContext context, String id) {
    final transactions = getIt<TransactionViewModel>();
    if (!transactions.composerReady) transactions.load();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TransactionEditor(model: transactions, transactionId: id),
      ),
    );
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
    const gap = SizedBox(height: FreevaSpace.s6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (previous != null && !monthFlow(previous, main).isEmpty) ...[
          NewMonthReviewCard(
            monthLabel: _monthLabel(context, previous.period.from),
            flow: monthFlow(previous, main),
            minorDigits: digits(main),
          ),
          gap,
        ],
        SpendingBlock(
          breakdown: spendingBreakdown(data.month, main, data.categories),
          currency: main,
          minorDigits: digits(main),
          monthLabel: _monthLabel(context, data.month.period.from),
          otherCurrencies: otherCurrencySpending(data.month, main),
          digitsOf: digits,
        ),
        gap,
        // Goal-based ordering (debt goal → above spending) comes with group A.
        if (cards.isNotEmpty) ...[
          CreditCardsBlock(cards: cards, today: today, digitsOf: digits),
          gap,
        ],
        RecentTransactions(
          rows: rows,
          digitsOf: digits,
          onOpen: (id) => _open(context, id),
        ),
      ],
    );
  }
}
