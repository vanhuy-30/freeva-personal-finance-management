import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../domain/credit_card_status.dart';
import '../../../domain/wallet.dart';
import '../../viewmodels/wallet_detail_view_model.dart';
import 'credit_balance_card.dart';
import 'credit_info_card.dart';
import 'wallet_action_pill.dart';
import 'wallet_balance_card.dart';
import 'wallet_history.dart';

/// What the record screen opens with from a wallet.
enum WalletRecordAction { record, transfer, payCard }

/// Wallet detail (D, màn 3) or credit card detail (màn 4): wash card, card
/// info, two actions, the wallet's transactions by day.
class WalletDetailBody extends StatelessWidget {
  const WalletDetailBody({
    required this.wallet,
    required this.minorDigits,
    required this.today,
    required this.hidden,
    required this.main,
    required this.detail,
    required this.onRecord,
    required this.onRefresh,
    super.key,
  });

  final Wallet wallet;
  final int minorDigits;
  final DateTime today;
  final bool hidden;
  final TransactionViewModel main;
  final WalletDetailViewModel detail;
  final ValueChanged<WalletRecordAction> onRecord;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final locale = Localizations.localeOf(context).toString();
    final credit = wallet.draft.type == WalletType.credit;
    final card = credit ? CreditCardStatus.of(wallet, today) : null;
    final results = detail.results;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 400 && results.hasMore) {
          results.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            margin,
            FreevaSpace.s1,
            margin,
            FreevaSpace.s8,
          ),
          children: [
            if (card != null) ...[
              CreditBalanceCard(
                card: card,
                minorDigits: minorDigits,
                hidden: hidden,
              ),
              const SizedBox(height: FreevaSpace.s4),
              CreditInfoCard(card: card, today: today),
            ] else
              WalletBalanceCard(
                wallet: wallet,
                minorDigits: minorDigits,
                flow: detail.flow,
                flowFailed: detail.flowFailed,
                monthLabel: DateFormat(
                  s.homeMonthPattern,
                  locale,
                ).format(today),
                hidden: hidden,
              ),
            const SizedBox(height: FreevaSpace.s4),
            Row(
              children: [
                Expanded(
                  child: WalletActionPill(
                    icon: LucideIcons.plus,
                    label: credit ? s.creditRecordFrom : s.walletRecordFrom,
                    onTap: () => onRecord(WalletRecordAction.record),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Expanded(
                  child: credit
                      ? WalletActionPill(
                          icon: LucideIcons.arrowUp,
                          label: s.creditPay,
                          onTap: () => onRecord(WalletRecordAction.payCard),
                        )
                      : WalletActionPill(
                          icon: LucideIcons.arrowLeftRight,
                          label: s.walletTransfer,
                          onTap: () => onRecord(WalletRecordAction.transfer),
                        ),
                ),
              ],
            ),
            const SizedBox(height: FreevaSpace.s5),
            WalletHistory(
              walletId: wallet.id,
              credit: credit,
              main: main,
              results: results,
              onChanged: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
