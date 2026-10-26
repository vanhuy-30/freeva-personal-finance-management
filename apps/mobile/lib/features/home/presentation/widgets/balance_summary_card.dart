import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/overview.dart';
import 'currency_pill.dart';
import 'month_flow_value.dart';

/// The one wash card: total balance, eye toggle, other-currency pills and
/// this month's income / expense. Hiding masks balances only.
class BalanceSummaryCard extends StatelessWidget {
  const BalanceSummaryCard({
    required this.summary,
    required this.flow,
    required this.monthLabel,
    required this.digitsOf,
    required this.hidden,
    required this.onToggleHidden,
    required this.onOpenWallets,
    super.key,
  });

  final BalanceSummary summary;
  final MonthFlow flow;
  final String monthLabel;
  final int Function(String currency) digitsOf;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onOpenWallets;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final main = summary.main;
    final label = summary.others.isEmpty
        ? s.homeTotalBalance(main.walletCount)
        : s.homeTotalBalanceIn(main.walletCount, main.currency);
    return WashSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.balanceCardFg,
                  ),
                ),
              ),
              FreevaIconButton(
                kind: FreevaIconButtonKind.onCard,
                icon: hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                label: hidden ? s.balanceShow : s.balanceHide,
                onPressed: onToggleHidden,
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyDisplay(
              minor: main.minor,
              currency: main.currency,
              minorDigits: digitsOf(main.currency),
              hidden: hidden,
              style: context.isCompactScreen
                  ? FreevaTypography.moneyDisplayCompact
                  : FreevaTypography.moneyDisplay,
            ),
          ),
          for (final other in summary.others)
            Padding(
              padding: const EdgeInsets.only(top: FreevaSpace.s2),
              child: CurrencyPill(
                balance: other,
                minorDigits: digitsOf(other.currency),
                hidden: hidden,
                onTap: onOpenWallets,
              ),
            ),
          const SizedBox(height: FreevaSpace.s4),
          MonthFlowRow(
            flow: flow,
            monthLabel: monthLabel,
            currency: main.currency,
            minorDigits: digitsOf(main.currency),
          ),
        ],
      ),
    );
  }
}
