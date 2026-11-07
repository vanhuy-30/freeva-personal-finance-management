import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../reports/presentation/widgets/donut_chart.dart';
import '../../domain/investment.dart';
import 'investment_labels.dart';

/// "Tỷ trọng theo danh mục": ring plus one legend row per category.
class InvestmentShareCard extends StatelessWidget {
  const InvestmentShareCard({
    required this.rows,
    required this.hidden,
    super.key,
  });

  final List<InvestmentTotal> rows;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final shown = [
      for (final r in rows)
        if ((r.shareBps ?? 0) > 0) r,
    ];
    final sum = shown.fold<int>(0, (a, r) => a + r.shareBps!);
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.investmentsAllocation,
            style: FreevaTypography.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (sum > 0)
                // Shares are display geometry only, never money.
                DonutChart(
                  size: 112,
                  fractions: [for (final r in shown) r.shareBps! / sum],
                  colors: [
                    for (final r in shown) investmentKindColor(c, r.kind!),
                  ],
                  center: '${shown.length}',
                  label: s.investmentsKinds,
                ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    for (final r in shown)
                      SizedBox(
                        height: 26,
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: investmentKindColor(c, r.kind!),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const SizedBox.square(dimension: 9),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                investmentKindName(s, r.kind!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FreevaTypography.bodyS.copyWith(
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              hidden
                                  ? '•••'
                                  : investmentPercent(r.shareBps!, locale),
                              style: FreevaTypography.bodyS.copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
