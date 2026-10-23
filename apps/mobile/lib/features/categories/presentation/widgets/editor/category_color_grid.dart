import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../category_badge.dart';
import '../category_names.dart';

/// "Màu": 7 columns of 34 swatches, "Không màu" first. The chosen one has a
/// white ring, a colour ring and a check.
class CategoryColorGrid extends StatelessWidget {
  const CategoryColorGrid({
    required this.colors,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  /// Palette from `/categories/options`, in grid order.
  final List<String> colors;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final cells = <String?>[null, ...colors];
    Widget swatch(String? token) {
      final color = categoryBadgeColor(token);
      final on = token == selected;
      return Semantics(
        container: true,
        inMutuallyExclusiveGroup: true,
        checked: on,
        button: true,
        label: categoryColorLabel(s, token),
        onTap: () => onChanged(token),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(token),
          child: SizedBox(
            height: FreevaSize.touch,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color ?? c.bgSubtle,
                  boxShadow: on
                      ? [
                          BoxShadow(color: c.bgSurface, spreadRadius: 3),
                          BoxShadow(
                            color: color ?? c.textSecondary,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: color == null
                    ? Icon(LucideIcons.ban, size: 16, color: c.textSecondary)
                    : on
                    ? Icon(LucideIcons.check, size: 16, color: c.textOnAction)
                    : null,
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: s.categoryColor,
      child: Column(
        children: [
          for (var row = 0; row * 7 < cells.length; row++)
            Row(
              children: [
                for (final token in cells.skip(row * 7).take(7))
                  Expanded(child: swatch(token)),
              ],
            ),
        ],
      ),
    );
  }
}
