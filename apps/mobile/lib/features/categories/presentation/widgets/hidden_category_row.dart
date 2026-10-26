import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/category_rules.dart';
import 'category_icon_tile.dart';

/// A hidden category, muted, with its hidden subcategory count and
/// "Khôi phục".
class HiddenCategoryRow extends StatelessWidget {
  const HiddenCategoryRow({
    required this.group,
    required this.busy,
    required this.onRestore,
    super.key,
  });

  final CategoryGroup group;
  final bool busy;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final category = group.parent;
    final count = group.children.length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
      child: Row(
        children: [
          CategoryIconTile(
            iconToken: category.iconToken,
            colorToken: category.colorToken,
            muted: true,
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (count > 0)
                  Text(
                    s.categoryChildCount(count),
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          Semantics(
            container: true,
            button: true,
            label: s.categoryRestoreNamed(category.name),
            excludeSemantics: true,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onRestore,
              icon: const Icon(LucideIcons.rotateCcw, size: 14),
              label: Text(s.categoryRestoreShort),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.actionPrimary,
                side: BorderSide(color: c.borderDefault),
                minimumSize: const Size(0, FreevaSize.touch),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                textStyle: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
