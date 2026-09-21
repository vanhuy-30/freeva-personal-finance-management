import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

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
          colors: [AppColors.primary, AppColors.highlight, AppColors.primary],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.5,
            colors: [AppColors.accent, AppColors.accent.withAlpha(0)],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.65,
              colors: [AppColors.surface, AppColors.highlight.withAlpha(0)],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.05),
                radius: .85,
                colors: [
                  AppColors.surface.withAlpha((.85 * 255).round()),
                  AppColors.surface.withAlpha(0),
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
