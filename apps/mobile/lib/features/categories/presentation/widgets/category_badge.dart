import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.g.dart';

IconData categoryIcon(String? token) => switch (token) {
  'food' => LucideIcons.utensils,
  'transport' => LucideIcons.bus,
  'housing' => LucideIcons.house,
  'bills' => LucideIcons.receipt,
  'shopping' => LucideIcons.shoppingBag,
  'health' => LucideIcons.heart,
  'education' => LucideIcons.graduationCap,
  'entertainment' => LucideIcons.clapperboard,
  'family' => LucideIcons.users,
  'gifts' => LucideIcons.gift,
  'travel' => LucideIcons.plane,
  'salary' => LucideIcons.banknote,
  'bonus' => LucideIcons.gift,
  'other_income' => LucideIcons.piggyBank,
  'other_expense' => LucideIcons.shapes,
  'transfer' => LucideIcons.arrowLeftRight,
  _ => LucideIcons.shapes,
};

/// Badge fill only. Highlight and muted tokens are never used as text color.
Color? categoryBadgeColor(String? token) => categoryPalette[token];

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
