import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
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
import 'glance_tile.dart';
import 'net_worth_parts.dart';

/// PA 3 wash card: "Tài sản ròng", the eye, this month's change, other
/// currencies, and the "Có" / "Nợ" boxes. Hiding masks the amounts only.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({
    required this.summary,
    required this.digitsOf,
    required this.hidden,
    required this.onToggleHidden,
    required this.onOpenAssets,
    required this.onOpenDebts,
    this.changeBps,
    this.investedMinor,
    this.onPickCurrency,
    this.onFixRate,
    super.key,
  });

  final BalanceSummary summary;
  final int Function(String currency) digitsOf;
  final bool hidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onOpenAssets;
  final VoidCallback onOpenDebts;

  /// Change since the month started; null hides the tag.
  final int? changeBps;

  /// Investments in the main currency; null when unknown.
  final BigInt? investedMinor;
  final VoidCallback? onPickCurrency;
  final void Function(String currency)? onFixRate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final main = summary.main;
    final digits = digitsOf(main.currency);
    final change = changeBps;
    return WashSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.homeNetWorth,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                    color: c.balanceCardFg,
                  ),
                ),
              ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyDisplay(
              minor: main.minor,
              currency: main.currency,
              minorDigits: digits,
              hidden: hidden,
              currencyColor: c.textOnWash,
              style: context.isCompactScreen
                  ? FreevaTypography.moneyDisplayCompact
                  : FreevaTypography.moneyDisplay,
            ),
          ),
          if (change != null) ...[
            const SizedBox(height: FreevaSpace.s1),
            GlanceTag(
              text: s.homeNetWorthChange(_percent(context, change.abs())),
              icon: change < 0 ? LucideIcons.arrowDown : LucideIcons.arrowUp,
              bg: c.bgSurface.withValues(alpha: .8),
              fg: change < 0 ? c.statusDanger : c.statusSuccess,
            ),
          ],
          for (final other in summary.others)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: CurrencyPill(
                balance: other,
                minorDigits: digitsOf(other.currency),
                hidden: hidden,
                onTap: onOpenAssets,
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
          NetWorthSplit(
            balance: main,
            digits: digits,
            hidden: hidden,
            investedMinor: investedMinor,
            onOpenAssets: onOpenAssets,
            onOpenDebts: onOpenDebts,
          ),
        ],
      ),
    );
  }

  static String _percent(BuildContext context, int bps) =>
      '${NumberFormat('#,##0.0', Localizations.localeOf(context).toString()).format(bps / 100)}%';
}
