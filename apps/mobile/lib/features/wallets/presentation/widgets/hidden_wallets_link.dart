import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// "Ví đã ẩn · N ›" under the wallet list.
class HiddenWalletsLink extends StatelessWidget {
  const HiddenWalletsLink({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '${s.walletHiddenTitle}, $count',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(LucideIcons.archive, size: 18, color: c.textOnWash),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.walletHiddenTitle,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: c.textOnWash,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
