import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../domain/spending_forecast.dart';
import 'forecast_chip.dart';
import 'spend_forecast_labels.dart';

/// Small tile with a label over a value: radius 16, padding 10×12. Tinted
/// green for the daily allowance.
class ForecastMiniTile extends StatelessWidget {
  const ForecastMiniTile({
    required this.label,
    required this.value,
    this.tone = ForecastTone.neutral,
    super.key,
  });

  final String label;
  final String value;
  final ForecastTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, ink) = toneColors(c, tone);
    final neutral = tone == ForecastTone.neutral;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: neutral ? c.textSecondary : ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FreevaTypography.titleM.copyWith(
              height: 1.2,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// CHI NHIỀU NHẤT THÁNG NÀY: up to three rows, icon tile 32, name and
/// amount, a 6 high bar at the category's share of the month.
class SpendTopCategories extends StatelessWidget {
  const SpendTopCategories({
    required this.items,
    required this.digits,
    super.key,
  });

  final List<SpendTopCategory> items;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final radius = BorderRadius.circular(FreevaComponent.listRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.listBg,
        borderRadius: radius,
        boxShadow: FreevaElevation.s1,
      ),
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.listDivider),
            _TopRow(
              item: item,
              amount: formatMoneyText(item.spentMinor, digits, locale),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.item, required this.amount});

  final SpendTopCategory item;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s2,
          ),
          child: Row(
            children: [
              Container(
                width: FreevaSize.iconTile,
                height: FreevaSize.iconTile,
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(FreevaRadius.xs),
                ),
                child: Icon(
                  categoryIcon(item.iconToken),
                  size: 17,
                  color: c.textOnWash,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: FreevaSpace.s2),
                        Text(
                          amount,
                          style: FreevaTypography.titleM.copyWith(
                            height: 1.2,
                            color: c.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FreevaProgressBar(
                      value: item.sharePercent / 100,
                      height: 6,
                      color: c.actionPrimary,
                      trackColor: c.borderDivider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "ⓘ Dự đoán theo mức chi trung bình…": how the figure is worked out.
class SpendForecastNote extends StatelessWidget {
  const SpendForecastNote({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.info,
              size: FreevaSize.iconChip,
              color: c.statusInfo,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.of(context).spendForecastNote,
              style: FreevaTypography.bodyS.copyWith(
                height: 19 / 13,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
