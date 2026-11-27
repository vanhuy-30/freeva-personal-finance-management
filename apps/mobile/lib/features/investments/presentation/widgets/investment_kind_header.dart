import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/total_card.dart';
import '../../domain/investment.dart';
import 'investment_asset_card.dart';
import 'investment_labels.dart';

/// Top card of the category screen: what is held in the category, its
/// quantity when one unit covers it, Vốn and Lãi/lỗ dự kiến.
class InvestmentKindHeader extends StatelessWidget {
  const InvestmentKindHeader({
    required this.row,
    required this.quantity,
    required this.currency,
    required this.digits,
    required this.hidden,
    this.expectedInterest,
    super.key,
  });

  final InvestmentTotal row;

  /// "9 chỉ"; null when the positions use different units.
  final String? quantity;
  final String currency;
  final int digits;
  final bool hidden;

  /// Set for deposits: principal and expected interest, no gain or loss.
  final BigInt? expectedInterest;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final kind = row.kind!;
    final (bg, fg) = investmentKindTint(c, kind);
    final bps = expectedInterest == null ? row.unrealizedBps : null;
    final interest = expectedInterest;
    final symbol = MoneyDisplay.symbolFor(currency);
    String money(BigInt v) => hidden
        ? '••••••'
        : expectedInterest == null
        ? formatMoneyText(v, digits, locale)
        : '${formatMoneyText(v, digits, locale)} $symbol';
    return DecoratedBox(
      decoration: totalCardDecoration(c),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TotalCardIcon(
                  icon: investmentKindIcon(kind),
                  background: bg,
                  foreground: fg,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.investmentHolding(investmentKindName(s, kind)),
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                if (bps != null && !hidden) InvestmentChangePill(bps: bps),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MoneyDisplay(
                minor: row.currentValueMinor,
                currency: currency,
                minorDigits: digits,
                style: FreevaTypography.moneyDisplayCompact.copyWith(
                  letterSpacing: -1,
                ),
                hidden: hidden,
              ),
            ),
            if (quantity != null) ...[
              const SizedBox(height: 4),
              Text(
                quantity!,
                style: FreevaTypography.bodyS.copyWith(
                  color: c.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: totalCardStatsDecoration(c),
              child: Padding(
                padding: totalCardStatsPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: s.investmentsCost,
                        value: money(row.costBasisMinor),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 34,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: c.borderDivider,
                    ),
                    Expanded(
                      child: interest != null
                          ? _Stat(
                              label: s.depositInterest,
                              value: hidden
                                  ? '••••••'
                                  : '${investmentSigned(interest, digits, locale)} $symbol',
                              color: c.moneyIncome,
                            )
                          : _Stat(
                              label: s.investmentsGain,
                              value: bps == null
                                  ? '—'
                                  : hidden
                                  ? '••••••'
                                  : investmentSigned(
                                      row.unrealizedMinor,
                                      digits,
                                      locale,
                                    ),
                              color: bps == null
                                  ? null
                                  : row.unrealizedMinor.isNegative
                                  ? c.moneyExpense
                                  : c.moneyIncome,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          style: FreevaTypography.bodyM.copyWith(
            fontWeight: FontWeight.w600,
            color: color ?? c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
