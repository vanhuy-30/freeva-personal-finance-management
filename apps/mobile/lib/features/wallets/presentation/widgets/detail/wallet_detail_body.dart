import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../installments/domain/card_installment.dart';
import '../../../../installments/presentation/widgets/installment_plans_group.dart';
import '../../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../../domain/credit_card_status.dart';
import '../../../domain/wallet.dart';
import '../../viewmodels/wallet_detail_view_model.dart';
import 'credit_balance_card.dart';
import 'credit_info_card.dart';
import 'credit_period_card.dart';
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
    required this.onReconcile,
    required this.onRefresh,
    this.periodDue,
    this.plans = const [],
    this.onOpenPlan,
    super.key,
  });

  final Wallet wallet;
  final int minorDigits;
  final DateTime today;
  final bool hidden;
  final TransactionViewModel main;
  final WalletDetailViewModel detail;
  final ValueChanged<WalletRecordAction> onRecord;
  final VoidCallback onReconcile;
  final Future<void> Function() onRefresh;

  /// Card with installments (`WCredit3`): "Phải trả kỳ này" replaces the
  /// card info, and the active plans list under "TRẢ GÓP".
  final CardPeriodDue? periodDue;
  final List<CardInstallment> plans;
  final ValueChanged<CardInstallment>? onOpenPlan;

  /// Gap between the sections on the board.
  static const double _gap = 18;

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
          // Board sections sit 18 apart (8 of it comes from the top bar).
          padding: EdgeInsets.fromLTRB(margin, 10, margin, FreevaSpace.s8),
          children: [
            if (card != null) ...[
              CreditBalanceCard(
                card: card,
                minorDigits: minorDigits,
                hidden: hidden,
              ),
              const SizedBox(height: _gap),
              if (periodDue case final due?)
                CreditPeriodCard(
                  due: due,
                  today: today,
                  minorDigits: minorDigits,
                  minimum: wallet.draft.minimumPayment,
                )
              else
                CreditInfoCard(
                  card: card,
                  today: today,
                  minorDigits: minorDigits,
                ),
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
                converted: detail.converted,
                convertedDigits:
                    main.currencies
                        .where((x) => x.code == detail.converted?.currency)
                        .map((x) => x.minorDigits)
                        .firstOrNull ??
                    0,
              ),
            if (!wallet.archived) ...[
              const SizedBox(height: FreevaSpace.s2),
              Align(
                child: TextButton.icon(
                  onPressed: onReconcile,
                  icon: const Icon(LucideIcons.scale, size: FreevaSize.iconSm),
                  label: Text(s.walletReconcileLink),
                  style: TextButton.styleFrom(
                    foregroundColor: context.colors.actionPrimary,
                    minimumSize: const Size(0, 44),
                    textStyle: FreevaTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: _gap),
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
                          icon: LucideIcons.arrowRightLeft,
                          label: s.walletTransfer,
                          onTap: () => onRecord(WalletRecordAction.transfer),
                        ),
                ),
              ],
            ),
            if (credit && plans.isNotEmpty && onOpenPlan != null) ...[
              const SizedBox(height: _gap),
              InstallmentPlansGroup(
                plans: plans,
                naming: TransactionNaming(
                  s,
                  categories: main.categories,
                  wallets: main.wallets,
                ),
                digitsOf: (code) =>
                    main.currencies
                        .where((x) => x.code == code)
                        .map((x) => x.minorDigits)
                        .firstOrNull ??
                    0,
                onOpen: onOpenPlan!,
              ),
            ],
            const SizedBox(height: _gap),
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
