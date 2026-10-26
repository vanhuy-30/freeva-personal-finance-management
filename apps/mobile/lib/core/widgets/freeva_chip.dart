import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

enum FreevaChipKind {
  /// Picking a value (category): ink border when selected. 40 high.
  choice,

  /// List filters: ink fill when on. 36 high, sits at the top of list screens.
  filter,
}

enum FreevaChipSize {
  /// Choice 40 / filter 36, 14 / 13 pt, padding 14.
  regular,

  /// 32 high, padding 12, 13/500 (600 selected).
  small,

  /// Choice chip 36 high, 13/500; selected 600 with a 1.5 ink border.
  compact,

  /// Choice chip 44 high, padding 16; selected is an ink fill, no border.
  large,
}

class FreevaChip extends StatelessWidget {
  const FreevaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.kind = FreevaChipKind.choice,
    this.size = FreevaChipSize.regular,
    this.icon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final FreevaChipKind kind;
  final FreevaChipSize size;
  final IconData? icon;

  /// For example a chevron on "Tháng 10 ▾"; drawn at 14.
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filter = kind == FreevaChipKind.filter;
    final filled = selected && (filter || size == FreevaChipSize.large);
    final fg = filled ? c.chipFilterSelectedFg : c.textPrimary;
    final side = filled
        ? BorderSide.none
        : selected
        ? BorderSide(color: c.chipSelectedBorder, width: FreevaBorder.selected)
        : BorderSide(color: c.chipBorder);
    final (double height, double padding, double fontSize) = switch (size) {
      FreevaChipSize.regular => (
        filter ? FreevaSize.buttonCompact : FreevaSize.buttonXs,
        14.0,
        filter ? 13.0 : 14.0,
      ),
      FreevaChipSize.small => (FreevaSize.pill, FreevaSpace.s3, 13.0),
      FreevaChipSize.compact => (FreevaSize.buttonCompact, 12.0, 13.0),
      FreevaChipSize.large => (FreevaSize.touch, FreevaSpace.s4, 14.0),
    };
    final style = FreevaTypography.body.copyWith(
      fontSize: fontSize,
      height: fontSize <= 13 ? FreevaTypography.bodyS.height : null,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: fg,
    );
    return Semantics(
      button: true,
      selected: selected,
      child: PressScale(
        enabled: onTap != null,
        child: Material(
          color: filled ? c.chipFilterSelectedBg : c.bgSurface,
          shape: StadiumBorder(side: side),
          child: InkWell(
            customBorder: const StadiumBorder(),
            splashFactory: NoSplash.splashFactory,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: height,
                minWidth: FreevaSize.touch,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: FreevaSize.iconChip, color: fg),
                      const SizedBox(width: 6),
                    ],
                    Text(label, style: style),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 4),
                      Icon(trailingIcon, size: FreevaSize.iconXs, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
