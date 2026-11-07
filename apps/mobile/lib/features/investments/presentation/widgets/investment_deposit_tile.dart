import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/investment.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import 'investment_asset_card.dart';

/// One deposit on the Tiền gửi category screen; opens its detail (P.11).
class InvestmentDepositTile extends StatelessWidget {
  const InvestmentDepositTile({
    required this.deposit,
    required this.digits,
    required this.hidden,
    required this.onTap,
    super.key,
  });

  final Investment deposit;
  final int digits;
  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final bps = deposit.unrealizedBps;
    final value = hidden
        ? '••••••'
        : formatMoneyText(deposit.currentValueMinor, digits, locale);
    final maturity = deposit.maturityDate == null
        ? null
        : s.investmentMaturity.isEmpty
        ? null
        : '${s.investmentMaturity} ${netWorthDate(deposit.maturityDate!, locale, year: true)}';
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      semanticsLabel: '${deposit.name}, $value',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deposit.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FreevaTypography.titleM.copyWith(
                      color: c.textPrimary,
                    ),
                  ),
                  if (maturity != null)
                    Text(
                      maturity,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (bps != null && !hidden) InvestmentChangePill(bps: bps),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
