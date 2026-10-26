import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/tokens.g.dart';

/// Lucide icon for a category token (36 picker icons plus older tokens).
IconData categoryIcon(String? token) => switch (token) {
  'food' => LucideIcons.utensils,
  'coffee' => LucideIcons.coffee,
  'groceries' => LucideIcons.shoppingBasket,
  'shopping' => LucideIcons.shoppingBag,
  'clothes' => LucideIcons.shirt,
  'gifts' => LucideIcons.gift,
  'transport' => LucideIcons.car,
  'bus' => LucideIcons.bus,
  'fuel' => LucideIcons.fuel,
  'travel' => LucideIcons.plane,
  'housing' => LucideIcons.house,
  'repair' => LucideIcons.wrench,
  'electricity' => LucideIcons.zap,
  'water' => LucideIcons.droplet,
  'internet' => LucideIcons.wifi,
  'phone' => LucideIcons.smartphone,
  'health' => LucideIcons.heartPulse,
  'medicine' => LucideIcons.pill,
  'sports' => LucideIcons.dumbbell,
  'family' => LucideIcons.users,
  'pets' => LucideIcons.pawPrint,
  'beauty' => LucideIcons.sparkles,
  'education' => LucideIcons.graduationCap,
  'books' => LucideIcons.bookOpen,
  'music' => LucideIcons.music,
  'entertainment' => LucideIcons.clapperboard,
  'games' => LucideIcons.gamepad2,
  'salary' => LucideIcons.banknote,
  'bonus' => LucideIcons.award,
  'investment' => LucideIcons.trendingUp,
  'work' => LucideIcons.briefcase,
  'other_income' => LucideIcons.piggyBank,
  'bills' => LucideIcons.receipt,
  'insurance' => LucideIcons.shieldCheck,
  'subscription' => LucideIcons.repeat,
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
