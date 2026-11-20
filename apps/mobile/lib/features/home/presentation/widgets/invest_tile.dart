import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../domain/overview_glance.dart';
import 'glance_painters.dart';
import 'glance_tile.dart';

/// "Đầu tư": a faint 30-day line, the gain in percent (green, red for a
/// loss) and "Lãi …" / "Lỗ …". Opens Investments.
class InvestTile extends StatelessWidget {
  const InvestTile({required this.glance, required this.digits, super.key});

  final InvestmentGlance glance;
  final int digits;

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
        : '${loss ? '−' : '+'}${NumberFormat('#,##0.0', locale).format(bps.abs() / 100)}%';
    final amount = formatMoneyText(
      glance.unrealizedMinor.abs(),
      digits,
      locale,
    );
    final line = loss ? s.homeInvestLoss(amount) : s.homeInvestGain(amount);
    return GlanceTile(
      semanticsLabel: [
        s.homeInvestTile,
        if (percent != null) percent,
        line,
      ].join(', '),
      onTap: () => context.push('/me/investments'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlanceHeader(
            icon: LucideIcons.trendingUp,
            label: s.homeInvestTile,
            bg: c.tintGreen,
            fg: c.tintGreenFg,
          ),
          const SizedBox(height: 10),
          if (glance.trend.length >= 2)
            Sparkline(values: glance.trend, color: tone)
          else
            const SizedBox(height: 34),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (percent != null)
                Text(percent, style: glanceBig(context).copyWith(color: tone)),
              const SizedBox(height: 2),
              Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: glanceNote(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
