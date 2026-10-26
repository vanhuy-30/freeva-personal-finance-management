import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Tag chip sizes: [inline] in a row's second line, [detail] 28 high on the
/// transaction detail, [sheet] 32 high in the tag picker.
enum TagChipSize { inline, detail, sheet }

/// Small violet chip for a tag ("#đi-làm").
class TagChip extends StatelessWidget {
  const TagChip(this.label, {this.size = TagChipSize.inline, super.key});

  final String label;
  final TagChipSize size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final inline = size == TagChipSize.inline;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: inline
          ? FreevaTypography.overline.copyWith(
              letterSpacing: 0,
              color: c.tintVioletFg,
            )
          : FreevaTypography.bodyS.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: c.tintVioletFg,
            ),
    );
    final decoration = BoxDecoration(
      color: c.tintViolet,
      borderRadius: BorderRadius.circular(FreevaRadius.full),
    );
    if (inline) {
      return Container(
        margin: const EdgeInsets.only(left: FreevaSpace.s1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: decoration,
        child: text,
      );
    }
    final detail = size == TagChipSize.detail;
    return Container(
      height: detail ? 28 : FreevaSize.pill,
      padding: EdgeInsets.symmetric(horizontal: detail ? 10 : FreevaSpace.s3),
      alignment: Alignment.center,
      decoration: decoration,
      child: text,
    );
  }
}
