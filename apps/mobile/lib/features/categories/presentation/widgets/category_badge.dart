import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/tokens.g.dart';

/// Lucide icon for a category token (36 picker icons plus older tokens).
IconData categoryIcon(String? token) => switch (token) {
  'food' => LucideIcons.utensils,
  'coffee' => LucideIcons.coffee,
  'groceries' => LucideIcons.shoppingCart,
  'shopping' => LucideIcons.handbag,
  'clothes' => LucideIcons.shirt,
  'gifts' => LucideIcons.gift,
  'transport' => LucideIcons.carFront,
  'bus' => LucideIcons.busFront,
  'fuel' => LucideIcons.fuel,
  'travel' => LucideIcons.plane,
  'housing' => LucideIcons.house,
  'repair' => LucideIcons.wrench,
  'electricity' => LucideIcons.zap,
  'water' => LucideIcons.droplet,
  'internet' => LucideIcons.wifi,
  'phone' => LucideIcons.smartphone,
  'health' => LucideIcons.heart,
  'medicine' => LucideIcons.pill,
  'sports' => LucideIcons.dumbbell,
  'family' => LucideIcons.users,
  'pets' => LucideIcons.pawPrint,
  'beauty' => LucideIcons.scissors,
  'education' => LucideIcons.graduationCap,
  'books' => LucideIcons.book,
  'music' => LucideIcons.music,
  'entertainment' => LucideIcons.film,
  'games' => LucideIcons.gamepad2,
  'salary' => LucideIcons.banknote,
  'bonus' => LucideIcons.star,
  'investment' => LucideIcons.trendingUp,
  'work' => LucideIcons.briefcase,
  'other_income' => LucideIcons.piggyBank,
  'bills' => LucideIcons.receiptText,
  'insurance' => LucideIcons.shield,
  'subscription' => LucideIcons.repeat,
  'transfer' => LucideIcons.arrowRightLeft,
  'other_expense' => LucideIcons.layoutGrid,
  _ => LucideIcons.layoutGrid,
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
