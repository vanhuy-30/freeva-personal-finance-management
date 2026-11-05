import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';

/// Opens the rule-based balance forecast, right under the month review row.
class ForecastLink extends StatelessWidget {
  const ForecastLink({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      list: true,
      onTap: () => context.push('/reports/forecast'),
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s4,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.trendingUp,
            size: FreevaSize.iconInline,
            color: c.tintBlueFg,
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Text(
              s.forecastTitle,
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
