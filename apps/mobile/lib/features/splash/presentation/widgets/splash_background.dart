import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.g.dart';

/// Soft overlapping brand washes, with a light center for the navy wordmark.
class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FreevaPrimitive.blue500,
            FreevaPrimitive.cyan300,
            FreevaPrimitive.blue500,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.5,
            colors: [
              FreevaPrimitive.violet500,
              FreevaPrimitive.violet500.withAlpha(0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.65,
              colors: [
                FreevaPrimitive.white,
                FreevaPrimitive.cyan300.withAlpha(0),
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.05),
                radius: .85,
                colors: [
                  FreevaPrimitive.white.withAlpha((.85 * 255).round()),
                  FreevaPrimitive.white.withAlpha(0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
