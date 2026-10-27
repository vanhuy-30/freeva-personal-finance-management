import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

enum FreevaButtonVariant {
  primary,
  ink,
  secondary,
  destructive,
  text,

  /// White with a red hairline and red label ("Xoá ví" at the end of a form).
  dangerOutline,

  /// Inline blue link, 13/500, no fill, no minimum width ("Xem giao dịch",
  /// "Xem cả 42"). The touch area stays 44 high.
  link,
}

enum FreevaButtonSize {
  /// 56, 16/600.
  l,

  /// 52, 15/600.
  m,

  /// 44, 14/600.
  s,

  /// 40, 14/600.
  xs,

  /// 48, 15/600, padding 20: dialog actions.
  dialog,

  /// 36 visual (44 touch), 13/600, padding 14: inline row actions.
  compact,
}

double freevaButtonHeight(FreevaButtonSize size) => switch (size) {
  FreevaButtonSize.l => FreevaSize.buttonL,
  FreevaButtonSize.m => FreevaSize.button,
  FreevaButtonSize.s => FreevaSize.buttonS,
  FreevaButtonSize.xs => FreevaSize.buttonXs,
  FreevaButtonSize.dialog => FreevaSize.buttonDialog,
  FreevaButtonSize.compact => FreevaSize.buttonCompact,
};

TextStyle _textStyle(FreevaButtonVariant variant, FreevaButtonSize size) {
  if (variant == FreevaButtonVariant.link) {
    return FreevaTypography.bodyS.copyWith(fontWeight: FontWeight.w500);
  }
  return switch (size) {
    FreevaButtonSize.l => FreevaTypography.titleM.copyWith(fontSize: 16),
    FreevaButtonSize.m || FreevaButtonSize.dialog => FreevaTypography.titleM,
    FreevaButtonSize.s ||
    FreevaButtonSize.xs => FreevaTypography.titleM.copyWith(fontSize: 14),
    FreevaButtonSize.compact => FreevaTypography.titleM.copyWith(fontSize: 13),
  };
}

double _horizontalPadding(FreevaButtonSize size) => switch (size) {
  FreevaButtonSize.l || FreevaButtonSize.m => FreevaSpace.s6,
  FreevaButtonSize.s || FreevaButtonSize.xs => FreevaSpace.s4,
  FreevaButtonSize.dialog => FreevaSpace.s5,
  FreevaButtonSize.compact => 14,
};

/// One style per variant. Disabled swaps to disabled tokens (not opacity);
/// focus draws a 1.5 primary outline.
ButtonStyle freevaButtonStyle(
  FreevaColors c,
  FreevaButtonVariant variant,
  FreevaButtonSize size,
) {
  final (bg, fg, pressed) = switch (variant) {
    FreevaButtonVariant.primary => (
      c.buttonPrimaryBg,
      c.buttonPrimaryFg,
      c.buttonPrimaryBgPressed,
    ),
    FreevaButtonVariant.ink => (
      c.buttonInkBg,
      c.buttonInkFg,
      Color.alphaBlend(c.buttonInkFg.withAlpha(36), c.buttonInkBg),
    ),
    FreevaButtonVariant.secondary => (
      c.buttonSecondaryBg,
      c.buttonSecondaryFg,
      c.bgSubtle,
    ),
    FreevaButtonVariant.destructive => (
      c.buttonDangerBg,
      c.buttonDangerFg,
      Color.alphaBlend(FreevaPrimitive.ink900.withAlpha(36), c.buttonDangerBg),
    ),
    FreevaButtonVariant.dangerOutline => (
      c.bgSurface,
      c.statusDanger,
      c.statusDangerBg,
    ),
    FreevaButtonVariant.text => (Colors.transparent, c.textLink, c.bgSubtle),
    FreevaButtonVariant.link => (
      Colors.transparent,
      c.textLink,
      Colors.transparent,
    ),
  };
  final link = variant == FreevaButtonVariant.link;
  final hasFill = variant != FreevaButtonVariant.text && !link;
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(
      link
          ? const Size(0, FreevaSize.touch)
          : Size(FreevaSize.touch, freevaButtonHeight(size)),
    ),
    padding: WidgetStatePropertyAll(
      link
          ? const EdgeInsets.symmetric(vertical: FreevaSpace.s2)
          : EdgeInsets.symmetric(horizontal: _horizontalPadding(size)),
    ),
    tapTargetSize: link ? MaterialTapTargetSize.shrinkWrap : null,
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(_textStyle(variant, size)),
    elevation: const WidgetStatePropertyAll(0),
    splashFactory: NoSplash.splashFactory,
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return hasFill ? c.buttonDisabledBg : Colors.transparent;
      }
      if (states.contains(WidgetState.pressed)) return pressed;
      return bg;
    }),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.disabled) ? c.buttonDisabledFg : fg,
    ),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: c.borderFocus, width: FreevaBorder.selected);
      }
      if (states.contains(WidgetState.disabled)) return BorderSide.none;
      return switch (variant) {
        FreevaButtonVariant.secondary => BorderSide(
          color: c.buttonSecondaryBorder,
        ),
        FreevaButtonVariant.dangerOutline => BorderSide(color: c.borderDanger),
        _ => BorderSide.none,
      };
    }),
  );
}
