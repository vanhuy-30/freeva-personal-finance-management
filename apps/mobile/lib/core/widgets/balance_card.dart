import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// The one card with the colour wash. Only on Overview, wallet detail and
/// the Welcome sample.
class WashSurface extends StatelessWidget {
  const WashSurface({
    required this.child,
    this.padding = const EdgeInsets.all(FreevaSpace.s5),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.balanceCardRadius);
    Widget layer(Color color, Alignment center, double radius, double stop) =>
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: radius,
                colors: [color, color.withValues(alpha: 0)],
                stops: [0, stop],
              ),
            ),
          ),
        );
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: c.balanceCardBg)),
          layer(c.balanceCardWashTopRight, Alignment.topRight, 1.2, .55),
          layer(c.balanceCardWashBottomLeft, Alignment.bottomLeft, 0.9, .6),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Small white-72% tile on the wash (income / expense of the month).
class WashStatTile extends StatelessWidget {
  const WashStatTile({required this.label, required this.value, super.key});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgSurface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.balanceCardFg,
            ),
          ),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
  }
}
