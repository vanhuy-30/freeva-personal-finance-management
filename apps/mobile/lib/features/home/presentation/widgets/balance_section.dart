import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/overview_summary.dart';
import '../viewmodels/home_view_model.dart';
import 'balance_error_card.dart';
import 'balance_summary_card.dart';
import 'overview_states.dart';

/// Balance card slot: skeleton (B6), error card (B8) or the wash card.
class BalanceSection extends StatelessWidget {
  const BalanceSection({required this.model, this.compact = false, super.key});

  final HomeViewModel model;

  /// First-run card: label and total only.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final data = model.data;
    if (model.status == HomeStatus.loading || data == null) {
      return model.status == HomeStatus.error
          ? BalanceErrorCard(onRetry: model.load)
          : const BalanceSkeleton();
    }
    final summary = balanceSummary(data, model.currency);
    return BalanceSummaryCard(
      summary: summary,
      flow: monthFlow(data.month, summary.main.currency),
      monthLabel: DateFormat(
        S.of(context).homeMonthPattern,
        Localizations.localeOf(context).toString(),
      ).format(DateTime.parse(data.month.period.from)),
      digitsOf: data.digitsOf,
      hidden: model.balancesHidden,
      onToggleHidden: model.toggleBalances,
      onOpenWallets: () => context.push('/wallets'),
      compact: compact,
    );
  }
}
