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

class FreevaChip extends StatelessWidget {
  const FreevaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.kind = FreevaChipKind.choice,
    this.icon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final FreevaChipKind kind;
  final IconData? icon;

  /// For example a chevron on "Tháng 10 ▾".
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filter = kind == FreevaChipKind.filter;
    final filled = filter && selected;
    final fg = filled ? c.chipFilterSelectedFg : c.textPrimary;
    final side = selected && !filter
        ? BorderSide(color: c.chipSelectedBorder, width: FreevaBorder.selected)
        : filled
        ? BorderSide.none
        : BorderSide(color: c.chipBorder);
    final style = (filter ? FreevaTypography.bodyS : FreevaTypography.body)
        .copyWith(
          fontSize: filter ? 13 : 14,
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
                minHeight: filter ? 36 : FreevaSize.buttonXs,
                minWidth: FreevaSize.touch,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      Icon(trailingIcon, size: FreevaSize.iconChip, color: fg),
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
