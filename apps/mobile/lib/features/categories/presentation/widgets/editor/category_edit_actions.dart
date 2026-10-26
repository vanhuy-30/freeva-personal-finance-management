import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// "Ẩn · Xoá" text buttons under the edit form. A main category that still
/// has subcategories greys them and says "Còn N danh mục con".
class CategoryEditActions extends StatelessWidget {
  const CategoryEditActions({
    required this.onHide,
    required this.onDelete,
    required this.children,
    super.key,
  });

  /// Null when blocked or busy.
  final VoidCallback? onHide;
  final VoidCallback? onDelete;

  /// Subcategories (hidden ones too); > 0 shows the reason line.
  final int children;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    ButtonStyle style(Color color) => TextButton.styleFrom(
      foregroundColor: color,
      disabledForegroundColor: c.textDisabled,
      minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
      padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
      textStyle: FreevaTypography.body.copyWith(fontWeight: FontWeight.w500),
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onHide,
              icon: const Icon(LucideIcons.eyeOff, size: 18),
              label: Text(s.categoryHideShort),
              style: style(c.textOnWash),
            ),
            const SizedBox(width: FreevaSpace.s2),
            TextButton.icon(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2, size: 18),
              label: Text(s.categoryDeleteShort),
              style: style(c.actionDanger),
            ),
          ],
        ),
        if (children > 0)
          Text(
            s.categoryChildrenBlock(children),
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
      ],
    );
  }
}
