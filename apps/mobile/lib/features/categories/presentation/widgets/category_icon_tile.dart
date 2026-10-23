import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'category_badge.dart';

/// Two-tone colours of a category: a light fill and a deeper stroke of the
/// same hue. No colour (or an unknown token) is the neutral subtle tile.
/// Category colours are never used for text.
(Color, Color) categoryTwoTone(BuildContext context, String? colorToken) {
  final c = context.colors;
  final color = categoryBadgeColor(colorToken);
  if (color == null) return (c.bgSubtle, c.textPrimary);
  final dark = Theme.of(context).brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(color);
  final stroke = dark
      ? hsl.withLightness(hsl.lightness.clamp(.62, .8)).toColor()
      : hsl.withLightness(hsl.lightness.clamp(.2, .44)).toColor();
  final fill = Color.lerp(c.bgSurface, color, dark ? .24 : .16)!;
  return (fill, stroke);
}

/// 40 tile (radius 12) with the category's icon in its two tones. [muted]
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
            size >= 40 ? FreevaRadius.sm : size * .3,
          ),
        ),
        child: Icon(
          categoryIcon(iconToken),
          size: size >= 40 ? FreevaSize.iconInline : size * .5,
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
