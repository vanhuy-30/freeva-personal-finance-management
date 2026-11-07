import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
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
    super.key,
  });

  final InvestmentTotal row;

  /// "9 chỉ"; null when the positions use different units.
  final String? quantity;
  final String currency;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final kind = row.kind!;
    final (bg, fg) = investmentKindTint(c, kind);
    final bps = row.unrealizedBps;
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.6, -1),
          end: const Alignment(0.6, 1),
          colors: [c.tintBlue, c.bgSurface],
        ),
        border: Border.all(color: c.borderDivider),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox.square(
                    dimension: 32,
                    child: Icon(investmentKindIcon(kind), size: 16, color: fg),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  s.investmentHolding(investmentKindName(s, kind)),
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Align(
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
                ),
                if (bps != null && !hidden) InvestmentChangePill(bps: bps),
              ],
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
              decoration: BoxDecoration(
                color: c.bgSurface.withValues(alpha: 0.8),
                border: Border.all(color: c.borderDivider),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                      child: _Stat(
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
