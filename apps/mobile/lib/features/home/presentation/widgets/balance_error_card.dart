import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button_style.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/press_scale.dart';

/// Load failed and nothing is saved yet: replaces the balance card. Centred
/// alert tile, title, reassurance and "Thử lại".
class BalanceErrorCard extends StatelessWidget {
  const BalanceErrorCard({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Semantics(
      liveRegion: true,
      child: FreevaCard(
        padding: const EdgeInsets.symmetric(
          horizontal: FreevaSpace.s5,
          vertical: FreevaSpace.s6,
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.statusDangerBg,
                borderRadius: BorderRadius.circular(FreevaRadius.md),
              ),
              child: Icon(
                LucideIcons.circleAlert,
                size: 22,
                color: c.statusDanger,
              ),
            ),
            const SizedBox(height: FreevaSpace.s3),
            Text(
              s.homeErrorTitle,
              textAlign: TextAlign.center,
              style: FreevaTypography.titleL.copyWith(
                height: 1.2,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              s.homeErrorBody,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyM.copyWith(
                height: 1.2,
                color: c.textSecondary,
              ),
            ),
            const SizedBox(height: FreevaSpace.s4),
            // Secondary, 44 high, padding 20, 15/600 (as in EmptyState).
            PressScale(
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(
                  LucideIcons.rotateCw,
                  size: FreevaSize.iconChip,
                ),
                label: Text(s.commonRetry),
                style:
                    freevaButtonStyle(
                      c,
                      FreevaButtonVariant.secondary,
                      FreevaButtonSize.s,
                    ).copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: FreevaSpace.s5),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        FreevaTypography.titleM,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
