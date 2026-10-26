import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../category_icon_tile.dart';

/// 44 cell (radius 14) in an icon grid. The chosen one takes the selected
/// colour's tint and a border in its stroke (primary when no colour).
class CategoryIconCell extends StatelessWidget {
  const CategoryIconCell({
    required this.icon,
    required this.label,
    required this.selected,
    required this.colorToken,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final String? colorToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (fill, stroke) = colorToken == null
        ? (c.tintBlue, c.actionPrimary)
        : categoryTwoTone(context, colorToken);
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: FreevaSize.touch,
          decoration: BoxDecoration(
            color: selected ? fill : c.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? stroke : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: Icon(
            icon,
            size: FreevaSize.iconInline,
            color: selected ? stroke : c.textOnWash,
          ),
        ),
      ),
    );
  }
}

/// Lays [cells] out in rows of 6 with 8 gaps.
class IconGridRows extends StatelessWidget {
  const IconGridRows({required this.cells, super.key});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var row = 0; row * 6 < cells.length; row++) ...[
        if (row > 0) const SizedBox(height: FreevaSpace.s2),
        Row(
          children: [
            for (var i = 0; i < 6; i++) ...[
              if (i > 0) const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: row * 6 + i < cells.length
                    ? cells[row * 6 + i]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}
