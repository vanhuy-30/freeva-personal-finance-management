import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/balance_card.dart';
import '../../../../../core/widgets/money_display.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../../home/presentation/widgets/month_flow_value.dart';
import '../../../domain/wallet.dart';
import '../../../domain/wallet_flow.dart';
import '../wallet_labels.dart';
import '../wallet_type_icon.dart';

/// Wash card of a wallet: "Ngân hàng · VND", balance, money in / out this
/// month (transfers included).
class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    required this.wallet,
    required this.minorDigits,
    required this.flow,
    required this.flowFailed,
    required this.monthLabel,
    required this.hidden,
    super.key,
  });

  final Wallet wallet;
  final int minorDigits;

  /// Null while loading or after [flowFailed].
  final WalletFlow? flow;
  final bool flowFailed;
  final String monthLabel;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final currency = wallet.draft.currency;
    final compact = context.isCompactScreen;
    Widget value(BigInt? minor, MoneyTone tone) => minor != null
        ? MonthFlowValue(
            minor: minor,
            tone: tone,
            currency: currency,
            minorDigits: minorDigits,
          )
        : flowFailed
        ? Text(
            '—',
            style: FreevaTypography.titleM.copyWith(color: c.textOnWash),
          )
        : const Padding(
            padding: EdgeInsets.symmetric(vertical: 3),
            child: SkeletonBox(width: 72, height: 14, onWash: true),
          );
    return WashSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.bgSurface.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    walletTypeIconData(wallet.draft.type),
                    size: 16,
                    color: c.actionPrimary,
                  ),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: Text(
                  s.walletTypeCurrency(
                    walletTypeLabel(s, wallet.draft.type),
                    currency,
                  ),
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textOnWash,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FreevaSpace.s2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyDisplay(
              minor: wallet.balance,
              currency: currency,
              minorDigits: minorDigits,
              style: compact
                  ? FreevaTypography.moneyDisplayCompact
                  : FreevaTypography.moneyDisplay,
              hidden: hidden,
            ),
          ),
          const SizedBox(height: FreevaSpace.s4),
          Row(
            children: [
              Expanded(
                child: WashStatTile(
                  label: s.walletMonthIn(monthLabel),
                  value: value(flow?.moneyIn, MoneyTone.income),
                ),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: WashStatTile(
                  label: s.walletMonthOut(monthLabel),
                  value: value(flow?.moneyOut, MoneyTone.expense),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
