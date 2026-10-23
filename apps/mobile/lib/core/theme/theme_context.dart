import 'package:flutter/material.dart';

import 'tokens.g.dart';

extension FreevaThemeContext on BuildContext {
  /// Semantic and component colours for the current brightness.
  FreevaColors get colors =>
      Theme.of(this).extension<FreevaColors>() ?? FreevaColors.light;

  /// Screen margin: 20, or 16 on screens up to 340 pt wide.
  double get screenMargin =>
      MediaQuery.sizeOf(this).width <= FreevaLayout.compactBreakpoint
      ? FreevaLayout.screenMarginCompact
      : FreevaLayout.screenMargin;

  bool get isCompactScreen =>
      MediaQuery.sizeOf(this).width <= FreevaLayout.compactBreakpoint;

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
