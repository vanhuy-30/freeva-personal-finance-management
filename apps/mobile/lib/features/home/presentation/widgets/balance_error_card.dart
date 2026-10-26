import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_card.dart';

/// Load failed and nothing is saved yet: replaces the balance card.
class BalanceErrorCard extends StatelessWidget {
  const BalanceErrorCard({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return FreevaCard(
      padding: const EdgeInsets.all(FreevaSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.statusDangerBg,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: Icon(
              LucideIcons.cloudAlert,
              size: FreevaSize.iconInline,
              color: c.statusDanger,
            ),
          ),
          const SizedBox(height: FreevaSpace.s3),
          Text(
            s.homeErrorTitle,
            style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
          ),
          Text(
            s.homeErrorBody,
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FreevaSpace.s4),
          FreevaButton(
            label: s.commonRetry,
            variant: FreevaButtonVariant.secondary,
            size: FreevaButtonSize.s,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
