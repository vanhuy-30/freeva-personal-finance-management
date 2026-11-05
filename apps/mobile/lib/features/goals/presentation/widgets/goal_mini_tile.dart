import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Small grey tile with a label over a value: radius 16, padding 10×12.
class GoalMiniTile extends StatelessWidget {
  const GoalMiniTile({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgSubtle,
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FreevaTypography.titleM.copyWith(
              height: 1.2,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
