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
    final restore = busy ? null : onRestore;
    // 10 + the 44 touch box + 10 = the board's 64 row (40 tile + 12 + 12).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          const SizedBox(width: FreevaSpace.s3),
          // 36 pill in a 44 touch box.
          Semantics(
            container: true,
            button: true,
            enabled: restore != null,
            label: s.categoryRestoreNamed(category.name),
            onTap: restore,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: restore,
              child: SizedBox(
                height: FreevaSize.touch,
                child: Center(
                  child: OutlinedButton(
                    onPressed: restore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.actionPrimary,
                      backgroundColor: c.bgSurface,
                      disabledForegroundColor: c.textDisabled,
                      side: BorderSide(color: c.borderDefault),
                      minimumSize: const Size(0, FreevaSize.buttonCompact),
                      fixedSize: const Size.fromHeight(
                        FreevaSize.buttonCompact,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: const StadiumBorder(),
                      textStyle: FreevaTypography.bodyS.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.rotateCcw,
                          size: FreevaSize.iconXs,
                        ),
                        const SizedBox(width: 6),
                        Text(s.categoryRestoreShort),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
