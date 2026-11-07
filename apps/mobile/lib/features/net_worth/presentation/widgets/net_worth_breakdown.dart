import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../domain/net_worth_history.dart';

/// Assets and debts side by side, then what the assets are made of.
class NetWorthBreakdown extends StatelessWidget {
  const NetWorthBreakdown({
    required this.point,
    required this.currency,
    required this.digits,
    required this.hidden,
    super.key,
  });

  final NetWorthPoint point;
  final String currency;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    Widget amount(BigInt minor) => MoneyDisplay(
      minor: minor,
      currency: currency,
      minorDigits: digits,
      style: FreevaTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
      hidden: hidden,
    );
    Widget card(String title, BigInt minor) => Expanded(
      child: FreevaCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            amount(minor),
          ],
        ),
      ),
    );
    Widget row(IconData icon, String title, BigInt minor, Color bg, Color fg) =>
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: 14,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(icon, size: 16, color: fg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              amount(minor),
            ],
          ),
        );
    final wallet = point.walletMinor;
    final invested = point.investmentMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            card(s.netWorthAssets, point.assetsMinor),
            const SizedBox(width: 8),
            card(s.netWorthDebts, point.liabilitiesMinor),
          ],
        ),
        if (wallet != null && invested != null) ...[
          SectionHeader(s.netWorthInAssets),
          FreevaCard(
            list: true,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                row(
                  LucideIcons.walletMinimal,
                  s.netWorthWallets,
                  wallet,
                  c.tintViolet,
                  c.tintVioletFg,
                ),
                Divider(height: 1, color: c.borderDivider),
                row(
                  LucideIcons.chartLine,
                  s.netWorthInvestments,
                  invested,
                  c.tintBlue,
                  c.tintBlueFg,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
