import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'check_mark.dart';
import 'press_scale.dart';

/// Selectable card: icon and label on one row. Selected = `tint.blue` fill,
/// 1.5 primary border and a round check (or a radio dot with [radio]).
/// `enabled: false` dims it, for example when the maximum number of choices
/// is reached. [SelectableCard.tile] is the vertical goal tile.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.disabledOpacity,
    this.iconBoxSize,
    this.iconBoxRadius = FreevaRadius.xs,
    this.iconBg,
    this.iconColor,
    this.iconSize = FreevaSize.iconInline,
    this.radio = false,
    this.radius = FreevaRadius.lg,
    this.minHeight = FreevaSize.row,
    super.key,
  }) : tile = false;

  /// Vertical tile (onboarding goals): 120 high, radius 22, padding 14, icon
  /// box 38 r12 with a 20 glyph at the top, label 15/20 at the bottom, check
  /// badge 22 at 12/12.
  const SelectableCard.tile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
    this.disabledOpacity,
    this.iconBg,
    this.iconColor,
    super.key,
  }) : tile = true,
       iconBoxSize = 38,
       iconBoxRadius = FreevaRadius.sm,
       iconSize = FreevaSize.iconInline,
       radio = false,
       radius = FreevaRadius.lgx,
       minHeight = 120;

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// When set, a disabled card keeps its normal colours and is drawn at this
  /// opacity (boards use .55) instead of greying the text.
  final double? disabledOpacity;

  /// Puts the icon in a rounded box of this size; null = bare icon.
  final double? iconBoxSize;
  final double iconBoxRadius;

  /// Unselected icon box fill (default `bg.subtle`); selected is
  /// `bg.surface`.
  final Color? iconBg;

  /// Unselected glyph colour (default `text.primary`, or `tint.blueFg` when
  /// selected without a box); selected in a box is `action.primary`.
  final Color? iconColor;
  final double iconSize;

  /// Radio indicator: 22 ring (1.5 `border.strong`) when off, a 6 px
  /// `action.primary` ring around `bg.surface` when on.
  final bool radio;
  final double radius;
  final double minHeight;
  final bool tile;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final greyed = !enabled && disabledOpacity == null;
    final fg = greyed ? c.textDisabled : c.textPrimary;
    final boxed = iconBoxSize != null;
    final glyphColor = selected
        ? (boxed ? c.actionPrimary : c.tintBlueFg)
        : greyed
        ? fg
        : iconColor ?? c.textPrimary;
    Widget? iconWidget;
    if (icon != null) {
      final glyph = Icon(icon, size: iconSize, color: glyphColor);
      iconWidget = boxed
          ? Container(
              width: iconBoxSize,
              height: iconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.bgSurface : iconBg ?? c.bgSubtle,
                borderRadius: BorderRadius.circular(iconBoxRadius),
              ),
              child: glyph,
            )
          : glyph;
    }
    final labelText = Text(
      label,
      style: FreevaTypography.body.copyWith(
        height: tile ? 20 / 15 : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: fg,
      ),
    );
    final check = Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.actionPrimary),
      child: CheckMark(size: 12, strokeWidth: 3, color: c.textOnAction),
    );
    final Widget content;
    if (tile) {
      content = Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [if (iconWidget != null) iconWidget, labelText],
            ),
          ),
          if (selected) Positioned(top: 12, right: 12, child: check),
        ],
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FreevaSpace.s4,
          vertical: FreevaSpace.s3,
        ),
        child: Row(
          children: [
            if (iconWidget != null) ...[
              iconWidget,
              const SizedBox(width: FreevaSpace.s3),
            ],
            Expanded(child: labelText),
            if (radio)
              AnimatedContainer(
                duration: FreevaMotion.fast,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.bgSurface,
                  border: Border.all(
                    color: selected ? c.actionPrimary : c.borderStrong,
                    width: selected ? 6 : FreevaBorder.selected,
                  ),
                ),
              )
            else if (selected)
              check,
          ],
        ),
      );
    }
    Widget card = AnimatedContainer(
      duration: FreevaMotion.fast,
      constraints: tile
          ? BoxConstraints.tightFor(height: minHeight)
          : BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: selected ? c.tintBlue : c.bgSurface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected ? c.actionPrimary : c.borderDefault,
          width: selected ? FreevaBorder.selected : FreevaBorder.defaultValue,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        splashFactory: NoSplash.splashFactory,
        onTap: enabled ? onTap : null,
        child: content,
      ),
    );
    if (!enabled && disabledOpacity != null) {
      card = Opacity(opacity: disabledOpacity!, child: card);
    }
    return Semantics(
      button: !radio,
      inMutuallyExclusiveGroup: radio,
      checked: radio ? selected : null,
      selected: selected,
      enabled: enabled,
      child: PressScale(enabled: enabled, child: card),
    );
  }
}
