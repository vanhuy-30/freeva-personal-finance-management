import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'animated_brand_symbol.dart';

class SplashBrandContent extends StatelessWidget {
  const SplashBrandContent({
    super.key,
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final exit = reduceMotion
        ? 0.0
        : Curves.easeInOut.transform(
            ((progress - .84) / .16).clamp(0.0, 1.0),
          );
    final copy = reduceMotion
        ? 1.0
        : Curves.easeOut.transform(
            ((progress - .38) / .22).clamp(0.0, 1.0),
          );
    return Opacity(
      opacity: 1 - exit,
      child: Transform.scale(
        scale: 1 - .045 * exit,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => AnimatedBrandSymbol(
                progress: progress,
                reduceMotion: reduceMotion,
                size: (constraints.maxWidth * .94).clamp(0.0, 380.0),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: copy,
              child: Column(
                children: [
                  Text(
                    s.brandWordmark,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.text,
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 9,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.splashTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 17,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
