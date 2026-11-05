import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/overview.dart';
import 'convert_notes.dart';
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
    this.onPickCurrency,
    this.onFixRate,
    this.compact = false,
    super.key,
  });

  final BalanceSummary summary;
  final MonthFlow flow;
  final String monthLabel;
  final int Function(String currency) digitsOf;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onOpenWallets;

  /// Opens the display-currency chooser. Null hides the line.
  final VoidCallback? onPickCurrency;

  /// Opens the rate entry for a currency left out of the converted total.
  final void Function(String currency)? onFixRate;

  /// First-run card: label and total only (no eye, no month tiles).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final main = summary.main;
    final label = summary.isConverted
        ? s.homeTotalConverted(main.walletCount, main.currency)
        : summary.others.isEmpty
        ? s.homeTotalBalance(main.walletCount)
        : s.homeTotalBalanceIn(main.walletCount, main.currency);
    final labelText = Text(
      label,
      style: FreevaTypography.bodyS.copyWith(
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: c.balanceCardFg,
      ),
    );
    final amount = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: MoneyDisplay(
        minor: main.minor,
        currency: main.currency,
        minorDigits: digitsOf(main.currency),
        hidden: hidden,
        currencyColor: c.textOnWash,
        style: context.isCompactScreen
            ? FreevaTypography.moneyDisplayCompact
            : FreevaTypography.moneyDisplay,
      ),
    );
    if (compact) {
      return WashSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            labelText,
            const SizedBox(height: FreevaSpace.s1),
            amount,
          ],
        ),
      );
    }
    return WashSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row is the 44 touch box of the eye; its 36 circle sits flush
          // with the card padding (the touch box overhangs it by 4).
          Row(
            children: [
              Expanded(child: labelText),
              Transform.translate(
                offset: Offset(
                  Directionality.of(context) == TextDirection.ltr ? 4 : -4,
                  0,
                ),
                child: FreevaIconButton(
                  kind: FreevaIconButtonKind.onCard,
                  iconSize: FreevaSize.iconChip,
                  icon: hidden ? LucideIcons.eyeOff : LucideIcons.eye,
                  label: hidden ? s.balanceShow : s.balanceHide,
                  onPressed: onToggleHidden,
                ),
              ),
            ],
          ),
          amount,
          for (final other in summary.others)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CurrencyPill(
                balance: other,
                minorDigits: digitsOf(other.currency),
                hidden: hidden,
                onTap: onOpenWallets,
              ),
            ),
          for (final item in summary.unconverted)
            if (onFixRate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ConvertLine(
                  text: unconvertedText(s, item),
                  semanticsLabel: unconvertedText(s, item),
                  onTap: () => onFixRate!(item.currency),
                ),
              ),
          if (onPickCurrency != null &&
              (summary.others.isNotEmpty || summary.unconverted.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConvertLine(
                text: s.homeDisplayCurrencyAction(main.currency),
                semanticsLabel: s.homeDisplayCurrencyAction(main.currency),
                onTap: onPickCurrency!,
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
