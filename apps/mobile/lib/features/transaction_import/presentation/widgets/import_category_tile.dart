import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/press_scale.dart';

/// Category choice tile of board R.3: 48 high, radius 16, padding 0 12,
/// 28 icon box (radius 8, `bg.subtle`, 15 glyph), 14/500 label. Selected is
/// `tint.blue` with a 1.5 primary border, 600 label and a 20 check badge
/// sitting 6 outside the top-right corner.
class ImportCategoryTile extends StatelessWidget {
  const ImportCategoryTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.md);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: selected ? c.tintBlue : c.bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: BorderSide(
                  color: selected ? c.actionPrimary : c.borderDefault,
                  width: selected
                      ? FreevaBorder.selected
                      : FreevaBorder.defaultValue,
                ),
              ),
              child: InkWell(
                borderRadius: radius,
                splashFactory: NoSplash.splashFactory,
                onTap: onTap,
                child: SizedBox(
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FreevaSpace.s3,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.bgSubtle,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, size: 15, color: c.textOnWash),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.bodyM.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: c.sheetBg, spreadRadius: 2)],
                  ),
                  child: CheckMark(color: c.textOnAction, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
