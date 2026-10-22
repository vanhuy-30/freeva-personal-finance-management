import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/overview.dart';

/// Start of a new month: "Xem lại tháng 10 · Chi … · Thu …", opens Reports.
class NewMonthReviewCard extends StatelessWidget {
  const NewMonthReviewCard({
    required this.monthLabel,
    required this.flow,
    required this.minorDigits,
    super.key,
  });

  final String monthLabel;
  final MonthFlow flow;
  final int minorDigits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, minorDigits, locale);
    return FreevaCard(
      list: true,
      onTap: () => context.go('/reports'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: Icon(
              LucideIcons.calendarCheck,
              size: FreevaSize.iconInline,
              color: c.tintBlueFg,
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.homeReviewMonth(monthLabel),
                  style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
                ),
                Text(
                  s.homeReviewLine(money(flow.expense), money(flow.income)),
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: FreevaSize.iconInline,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}
