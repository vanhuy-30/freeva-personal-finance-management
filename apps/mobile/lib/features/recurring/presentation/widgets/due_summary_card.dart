import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';

/// "Cần trả 7.330.000 · 3 hóa đơn chưa trả · xem trên lịch"; opens the
/// calendar. [total] is already formatted.
class DueSummaryCard extends StatelessWidget {
  const DueSummaryCard({
    required this.total,
    required this.count,
    required this.onTap,
    super.key,
  });

  final String total;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.xs),
            ),
            child: Icon(LucideIcons.calendar, size: 17, color: c.tintBlueFg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.recDueTotal(total),
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.recDueCount(count),
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: c.textSecondary),
        ],
      ),
    );
  }
}
