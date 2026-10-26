import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'category_badge.dart';

/// Two-tone colours of a category: a light fill and a deeper stroke of the
/// same hue. Palette colours of the five brand families use their tint
/// tokens (as on the E boards); the rest get a 10% fill and a darkened
/// stroke. No colour (or an unknown token) is the neutral subtle tile.
/// Category colours are never used for text.
(Color, Color) categoryTwoTone(BuildContext context, String? colorToken) {
  final c = context.colors;
  final family = switch (colorToken) {
    'color.brand.primary' ||
    'color.category.blueDeep' ||
    'color.category.blueLight' => (c.tintBlue, c.tintBlueFg),
    'color.brand.secondary' ||
    'color.category.oceanDeep' ||
    'color.brand.highlight' => (c.tintCyan, c.tintCyanFg),
    'color.brand.accent' ||
    'color.category.violetDeep' ||
    'color.category.violetLight' => (c.tintViolet, c.tintVioletFg),
    'color.semantic.success' ||
    'color.category.greenLight' => (c.tintGreen, c.tintGreenFg),
    'color.semantic.warning' ||
    'color.category.yellowLight' => (c.statusWarningBg, c.statusWarning),
    _ => null,
  };
  if (family != null) return family;
  final color = categoryBadgeColor(colorToken);
  if (color == null) return (c.bgSubtle, c.textOnWash);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(color);
  final stroke = dark
      ? hsl.withLightness(hsl.lightness.clamp(.62, .8)).toColor()
      : hsl.withLightness(hsl.lightness.clamp(.2, .34)).toColor();
  final fill = Color.lerp(c.bgSurface, color, dark ? .24 : .1)!;
  return (fill, stroke);
}

/// Category icon tile in its two tones: 40/36 radius 12, 32 radius 10,
/// 60/64 previews radius 20 with a 28/30 glyph. [muted]
/// greys it out (hidden categories).
class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    required this.iconToken,
    required this.colorToken,
    this.size = 40,
    this.muted = false,
    super.key,
  });

  final String? iconToken;
  final String? colorToken;
  final double size;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = muted
        ? (c.bgSubtle, c.textSecondary)
        : categoryTwoTone(context, colorToken);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(
            size >= 60
                ? FreevaRadius.lg
                : size >= 36
                ? FreevaRadius.sm
                : FreevaRadius.xs,
          ),
        ),
        child: Icon(
          categoryIcon(iconToken),
          size: size >= 64
              ? 30
              : size >= 60
              ? 28
              : size / 2,
          color: fg,
        ),
      ),
    );
  }
}

/// 8 dot in the category's colour for subcategory rows; neutral when none.
class CategoryDot extends StatelessWidget {
  const CategoryDot({required this.colorToken, super.key});

  final String? colorToken;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: categoryBadgeColor(colorToken) ?? context.colors.dataMuted,
    ),
  );
}
