import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/freeva_toast.dart';

/// Stands in for the budget card until budgets exist (BE-P2-E02 / MOB-P2-E02).
class ReportBudgetRow extends StatelessWidget {
  const ReportBudgetRow({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      list: true,
      onTap: () => showFreevaToast(
        context,
        message: s.reportBudgetSoon,
        icon: LucideIcons.piggyBank,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.tintBlue,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                LucideIcons.plus,
                size: FreevaSize.iconInline,
                color: c.tintBlueFg,
              ),
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              s.reportBudgetSet,
              style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
            ),
          ),
          Icon(LucideIcons.chevronRight, size: 16, color: c.textSecondary),
        ],
      ),
    );
  }
}
