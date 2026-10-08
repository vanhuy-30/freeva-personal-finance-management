import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

IconData categoryIcon(String? token) => switch (token) {
  'food' => Icons.restaurant_outlined,
  'transport' => Icons.directions_bus_outlined,
  'housing' => Icons.home_outlined,
  'bills' => Icons.receipt_long_outlined,
  'shopping' => Icons.shopping_bag_outlined,
  'health' => Icons.favorite_outline,
  'education' => Icons.school_outlined,
  'entertainment' => Icons.movie_outlined,
  'family' => Icons.family_restroom_outlined,
  'gifts' => Icons.card_giftcard_outlined,
  'travel' => Icons.flight_outlined,
  'salary' => Icons.payments_outlined,
  'bonus' => Icons.redeem_outlined,
  'other_income' => Icons.savings_outlined,
  'other_expense' => Icons.category_outlined,
  _ => Icons.category_outlined,
};

/// Badge fill only. Highlight and muted tokens are never used as text color.
Color? categoryBadgeColor(String? token) => switch (token) {
  'color.brand.primary' => AppColors.primary,
  'color.brand.secondary' => AppColors.secondary,
  'color.brand.highlight' => AppColors.highlight,
  'color.brand.muted' => AppColors.muted,
  'color.brand.accent' => AppColors.accent,
  'color.semantic.success' => AppColors.success,
  'color.semantic.danger' => AppColors.danger,
  'color.semantic.warning' => AppColors.warning,
  'color.gradient.ctaStart' => AppColors.primary,
  'color.gradient.ctaEnd' => AppColors.accent,
  'color.gradient.splashAccent' => AppColors.secondary,
  'color.neutral.text' => AppColors.text,
  'color.neutral.textMuted' => AppColors.textMuted,
  'color.neutral.surface' => AppColors.surface,
  'color.neutral.canvas' => AppColors.canvas,
  'color.neutral.onPrimary' => AppColors.onPrimary,
  'color.dark.text' => AppColors.darkText,
  'color.dark.textMuted' => AppColors.darkTextMuted,
  'color.dark.surface' => AppColors.darkSurface,
  'color.dark.canvas' => AppColors.darkCanvas,
  'color.dark.onPrimary' => AppColors.onPrimary,
  _ => null,
};

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({this.colorToken, this.iconToken, super.key});
  final String? colorToken;
  final String? iconToken;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 16,
      backgroundColor:
          categoryBadgeColor(colorToken) ?? scheme.surfaceContainerHighest,
      child: Icon(categoryIcon(iconToken), size: 18, color: scheme.onSurface),
    );
  }
}
