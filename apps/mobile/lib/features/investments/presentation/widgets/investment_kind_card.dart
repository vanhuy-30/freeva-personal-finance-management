import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/investment.dart';
import 'investment_labels.dart';

/// One category: tile, name, asset names, change pill, and Giá trị · Vốn ·
/// Lãi/lỗ dự kiến. Unpriced positions show a tag and no gain.
class InvestmentKindCard extends StatelessWidget {
  const InvestmentKindCard({
    required this.row,
    required this.names,
    required this.digits,
    required this.hidden,
    super.key,
  });

  final InvestmentTotal row;
  final List<String> names;
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
    final noPrice = bps == null;
    String money(BigInt v) =>
        hidden ? '••••••' : formatMoneyText(v, digits, locale);
    final gain = noPrice
        ? '—'
        : hidden
        ? '••••••'
        : investmentSigned(row.unrealizedMinor, digits, locale);
    final gainColor = noPrice
        ? c.textSecondary
        : row.unrealizedMinor.isNegative
        ? c.moneyExpense
        : c.moneyIncome;
    final name = investmentKindName(s, kind);
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      semanticsLabel: s.investmentsSemantics(
        name,
        hidden ? '' : money(row.currentValueMinor),
        hidden ? '' : money(row.costBasisMinor),
        noPrice ? s.investmentsUnpriced : gain,
      ),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox.square(
                    dimension: 44,
                    child: Icon(investmentKindIcon(kind), size: 20, color: fg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.titleM.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      if (names.isNotEmpty)
                        Text(
                          names.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (noPrice)
                  _Tag(text: s.investmentsUnpriced)
                else if (!hidden)
                  _Change(bps: bps),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: c.borderDivider),
            const SizedBox(height: 12),
            Row(
              children: [
                _Column(
                  label: s.investmentsValue,
                  value: money(row.currentValueMinor),
                ),
                const SizedBox(width: 10),
                _Column(
                  label: s.investmentsCost,
                  value: money(row.costBasisMinor),
                ),
                const SizedBox(width: 10),
                _Column(
                  label: s.investmentsGain,
                  value: gain,
                  color: gainColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            style: FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Change extends StatelessWidget {
  const _Change({required this.bps});

  final int bps;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final negative = bps < 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: negative ? c.statusDangerBg : c.statusSuccessBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          investmentPill(bps, locale),
          maxLines: 1,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: negative ? c.moneyExpense : c.moneyIncome,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          text,
          maxLines: 1,
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w500,
            color: c.textSecondary,
          ),
        ),
      ),
    );
  }
}
