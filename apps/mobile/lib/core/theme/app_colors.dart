/// Projection of packages/design-tokens. Do not use raw hex in widgets.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF5680E9);
  static const Color secondary = Color(0xFF5AB9EA);
  static const Color highlight = Color(0xFF84CEEB);
  static const Color muted = Color(0xFFC1C8E4);
  static const Color accent = Color(0xFF8860D0);

  static const Color text = Color(0xFF1B1F3B);
  static const Color textMuted = Color(0xFF5C6378);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color canvas = Color(0xFFF4F6FB);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2F9E76);
  static const Color danger = Color(0xFFD64545);
  static const Color warning = Color(0xFFD4A017);

  static const Color darkText = Color(0xFFF4F6FB);
  static const Color darkTextMuted = Color(0xFFC1C8E4);
  static const Color darkSurface = Color(0xFF1B1F33);
  static const Color darkCanvas = Color(0xFF12141F);
}
