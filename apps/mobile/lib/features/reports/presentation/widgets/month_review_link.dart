import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/report.dart';

/// Opens the month-review screen for the fiscal month currently on Reports.
class MonthReviewLink extends StatelessWidget {
  const MonthReviewLink({required this.period, super.key});

  final ReportPeriod period;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      list: true,
      onTap: () => context.push('/reports/month-review?on=${period.from}'),
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s4,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendarCheck,
            size: FreevaSize.iconInline,
            color: c.tintBlueFg,
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              s.monthReviewOpen,
              style: FreevaTypography.titleM.copyWith(
                height: 1.2,
                color: c.textPrimary,
              ),
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: FreevaSize.iconChip,
            color: c.textSecondary,
          ),
        ],
      ),
    );
  }
}
