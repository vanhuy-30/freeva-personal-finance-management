import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

enum FreevaButtonVariant { primary, ink, secondary, destructive, text }

enum FreevaButtonSize { l, m, s, xs }

double freevaButtonHeight(FreevaButtonSize size) => switch (size) {
  FreevaButtonSize.l => FreevaSize.buttonL,
  FreevaButtonSize.m => FreevaSize.button,
  FreevaButtonSize.s => FreevaSize.buttonS,
  FreevaButtonSize.xs => FreevaSize.buttonXs,
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
    FreevaButtonVariant.text => (Colors.transparent, c.textLink, c.bgSubtle),
  };
  final small = size == FreevaButtonSize.s || size == FreevaButtonSize.xs;
  final hasFill = variant != FreevaButtonVariant.text;
  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(
      Size(FreevaSize.touch, freevaButtonHeight(size)),
    ),
    padding: WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: small ? FreevaSpace.s4 : FreevaSpace.s6),
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: WidgetStatePropertyAll(
      small
          ? FreevaTypography.titleM.copyWith(fontSize: 14)
          : FreevaTypography.titleM,
    ),
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
      if (variant == FreevaButtonVariant.secondary &&
          !states.contains(WidgetState.disabled)) {
        return BorderSide(color: c.buttonSecondaryBorder);
      }
      return BorderSide.none;
    }),
  );
}
