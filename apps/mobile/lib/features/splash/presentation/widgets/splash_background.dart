import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.g.dart';

/// A clean light wash: white to a pale brand blue, with only a faint violet
/// at the bottom corner, so the wordmark and symbol carry the screen.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FreevaPrimitive.white,
            FreevaPrimitive.blue50,
            FreevaPrimitive.blue100,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.3,
            colors: [
              FreevaPrimitive.violet500.withAlpha((.16 * 255).round()),
              FreevaPrimitive.violet500.withAlpha(0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -.1),
              radius: .8,
              colors: [
                FreevaPrimitive.white.withAlpha((.9 * 255).round()),
                FreevaPrimitive.white.withAlpha(0),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
