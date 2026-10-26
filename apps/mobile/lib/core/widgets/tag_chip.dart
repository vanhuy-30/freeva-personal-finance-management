import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Small accent chip for a tag ("#đi-làm").
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(left: FreevaSpace.s1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.tintViolet,
        borderRadius: BorderRadius.circular(FreevaRadius.full),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FreevaTypography.overline.copyWith(
          letterSpacing: 0,
          color: c.tintVioletFg,
        ),
      ),
    );
  }
}
