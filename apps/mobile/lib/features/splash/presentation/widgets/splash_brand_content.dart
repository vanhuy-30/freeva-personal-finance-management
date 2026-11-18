import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
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
        : Curves.easeInOut.transform(((progress - .84) / .16).clamp(0.0, 1.0));
    final copy = reduceMotion
        ? 1.0
        : Curves.easeOut.transform(((progress - .38) / .22).clamp(0.0, 1.0));
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
                size: (constraints.maxWidth * .62).clamp(0.0, 260.0),
              ),
            ),
            const SizedBox(height: 28),
            Opacity(
              opacity: copy,
              child: Column(
                children: [
                  // Sora 600 with wide tracking: a geometric face that sits
                  // with the symbol's curves.
                  Text(
                    s.brandWordmark,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Sora',
                      fontVariations: [FontVariation('wght', 600)],
                      fontSize: 34,
                      height: 1.1,
                      letterSpacing: 8,
                      color: FreevaPrimitive.ink900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.splashTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FreevaPrimitive.ink600,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
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
