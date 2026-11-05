import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'goal_look.dart';

/// Goal kind as a 44-high chip with its icon tile; the picked one has a 1.5
/// ink border and heavier text.
class GoalKindChip extends StatelessWidget {
  const GoalKindChip({
    required this.kind,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.tileSize = 28,
    super.key,
  });

  final String kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Icon tile: 28 in the goal editor, 24 (board ObSaving, 14 side padding)
  /// on the first-run question.
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 44,
          padding: tileSize <= 24
              ? const EdgeInsets.symmetric(horizontal: 14)
              : const EdgeInsetsDirectional.fromSTEB(8, 0, 12, 0),
          decoration: BoxDecoration(
            color: c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.full),
            border: Border.all(
              color: selected ? c.textPrimary : c.chipBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoalIconTile(kind: kind, size: tileSize),
              const SizedBox(width: 6),
              // Flexible: a long label at large text on a narrow screen
              // shortens instead of pushing past the chip.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
