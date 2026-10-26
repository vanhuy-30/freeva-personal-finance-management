import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// "Ví đã ẩn · N ›" / "Danh mục đã ẩn · N ›" under a list.
class HiddenItemsLink extends StatelessWidget {
  const HiddenItemsLink({
    required this.label,
    required this.count,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      label: '$label, $count',
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
                    label,
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
                const SizedBox(width: 10),
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
