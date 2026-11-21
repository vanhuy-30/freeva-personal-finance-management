import 'package:flutter/material.dart';

import '../../../../core/widgets/freeva_toast.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../settings/presentation/widgets/choice_sheet.dart';
import '../../../transactions/presentation/widgets/composer/rate_dialog.dart';
import '../../domain/overview_glance.dart';
import '../../domain/overview_summary.dart';
import '../viewmodels/home_view_model.dart';
import 'balance_error_card.dart';
import 'balance_summary_card.dart';
import 'net_worth_card.dart';
import 'overview_states.dart';

/// Balance card slot: skeleton (B6), error card (B8), the net worth card
/// (PA 3) or, on the first run, the compact balance card.
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
    final summary = balanceSummary(data, model.displayCurrency);
    if (!compact) {
      final main = summary.main.currency;
      final trend = data.netWorthTrend;
      return NetWorthCard(
        summary: summary,
        digitsOf: data.digitsOf,
        hidden: model.balancesHidden,
        onToggleHidden: model.toggleBalances,
        onOpenAssets: () => context.push('/wallets'),
        onOpenDebts: () => context.push('/me/debts'),
        changeBps: summary.isConverted || trend?.currency != main
            ? null
            : netWorthChangeBps(trend, data.month.period.from),
        investedMinor: data.investments?.totalOf(main)?.currentValueMinor,
        onPickCurrency: !data.multiCurrency || model.currencyChoices.isEmpty
            ? null
            : () => _pickCurrency(context),
        onFixRate: (currency) => _fixRate(context, currency, main),
      );
    }
    return BalanceSummaryCard(
      summary: summary,
      flow: monthFlowFor(data, summary),
      monthLabel: DateFormat(
        S.of(context).homeMonthPattern,
        Localizations.localeOf(context).toString(),
      ).format(DateTime.parse(data.month.period.from)),
      digitsOf: data.digitsOf,
      hidden: model.balancesHidden,
      onToggleHidden: model.toggleBalances,
      onOpenWallets: () => context.push('/wallets'),
      onPickCurrency:
          compact || !data.multiCurrency || model.currencyChoices.isEmpty
          ? null
          : () => _pickCurrency(context),
      onFixRate: compact
          ? null
          : (currency) => _fixRate(context, currency, summary.main.currency),
      compact: compact,
    );
  }

  Future<void> _pickCurrency(BuildContext context) async {
    final s = S.of(context);
    final picked = await showChoiceSheet<String>(
      context,
      title: s.homeDisplayCurrencyTitle,
      selected: model.displayCurrency,
      options: [for (final code in model.currencyChoices) Choice(code, code)],
    );
    if (picked == null || picked == model.displayCurrency) return;
    if (!context.mounted) return;
    // Back to the profile currency is stored as "no choice".
    final ok = await model.chooseDisplayCurrency(
      picked == model.currency ? null : picked,
    );
    if (!ok && context.mounted) _snack(context, s.homeRateSaveFailed);
  }

  Future<void> _fixRate(BuildContext context, String from, String to) async {
    final s = S.of(context);
    final rate = await showRateDialog(
      context,
      value: '',
      label: s.homeRateInputLabel(from, to),
    );
    if (rate == null || rate.trim().isEmpty) return;
    final ok = await model.saveRate(from, to, rate);
    if (!ok && context.mounted) _snack(context, s.homeRateSaveFailed);
  }

  void _snack(BuildContext context, String text) =>
      showFreevaToast(context, message: text);
}
