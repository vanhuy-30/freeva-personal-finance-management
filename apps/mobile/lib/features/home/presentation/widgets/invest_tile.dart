import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../investments/presentation/widgets/investment_labels.dart';
import '../../domain/overview_glance.dart';
import 'glance_tile.dart';

/// "Đầu tư": current value, then ▲/▼ with the percent and the gain or loss
/// against the money put in (green up, red down). Opens Investments. When it
/// stands alone on its row ([wide]) it also shows the capital and the mix.
class InvestTile extends StatelessWidget {
  const InvestTile({
    required this.glance,
    required this.digits,
    this.wide = false,
    super.key,
  });

  final InvestmentGlance glance;
  final int digits;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final loss = glance.unrealizedMinor < BigInt.zero;
    final tone = loss ? c.statusDanger : c.moneyIncome;
    final bps = glance.unrealizedBps;
    final percent = bps == null
        ? null
        : '${loss ? '▼' : '▲'} ${NumberFormat('#,##0.0', locale).format(bps.abs() / 100)}%';
    final value = formatMoneyText(glance.valueMinor, digits, locale);
    final amount = formatMoneyText(
      glance.unrealizedMinor.abs(),
      digits,
      locale,
    );
    final line = s.homeInvestVsCost(loss ? '−$amount' : '+$amount');
    final kinds = glance.kinds.where((k) => k.kind != null).take(3).toList();
    final numbers = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(value, style: glanceBig(context)),
        ),
        if (percent != null) ...[
          const SizedBox(height: 2),
          Text(
            percent,
            style: glanceNote(context)
                .copyWith(color: tone, fontWeight: FontWeight.w600),
          ),
        ],
        Text(
          line,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: glanceNote(context).copyWith(color: tone),
        ),
      ],
    );
    return GlanceTile(
      semanticsLabel: [
        s.homeInvestTile,
        value,
        if (percent != null) percent,
        line,
      ].join(', '),
      onTap: () => context.push('/me/investments'),
      minHeight: wide ? 0 : 152,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlanceHeader(
            icon: LucideIcons.trendingUp,
            label: s.homeInvestTile,
            bg: c.tintGreen,
            fg: c.tintGreenFg,
          ),
          const SizedBox(height: 8),
          if (!wide)
            numbers
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: numbers),
                const SizedBox(width: FreevaSpace.s3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.investmentsCost, style: glanceNote(context)),
                    Text(
                      formatMoneyText(glance.costMinor, digits, locale),
                      style: FreevaTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (kinds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: c.borderDivider),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  for (final k in kinds)
                    _KindShare(
                      color: investmentKindTint(c, k.kind!).$2,
                      name: investmentKindName(s, k.kind!),
                      share: k.shareBps,
                      locale: locale,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _KindShare extends StatelessWidget {
  const _KindShare({
    required this.color,
    required this.name,
    required this.share,
    required this.locale,
  });

  final Color color;
  final String name;
  final int? share;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final pct = share == null
        ? ''
        : ' ${NumberFormat('#,##0', locale).format(share! / 100)}%';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$name$pct', style: glanceNote(context)),
      ],
    );
  }
}
