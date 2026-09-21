import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_symbol.dart';
import 'symbol_piece_clipper.dart';
import 'symbol_orbit.dart';

class AnimatedBrandSymbol extends StatelessWidget {
  const AnimatedBrandSymbol({
    super.key,
    required this.progress,
    required this.reduceMotion,
    required this.size,
  });

  final double size;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final glow = reduceMotion
        ? 0.0
        : math.sin(
            math.pi * ((progress - .57) / .26).clamp(0.0, 1.0),
          );
    return Semantics(
      label: S.of(context).appTitle,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.onPrimary
                          .withAlpha(((.20 + glow * .18) * 255).round()),
                      AppColors.onPrimary.withAlpha(0),
                    ],
                  ),
                ),
                child: SizedBox.square(dimension: size),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: SymbolOrbit(reduceMotion
                      ? 1
                      : ((progress - .35) / .25).clamp(0.0, 1.0)),
                ),
              ),
              for (var piece = 0; piece < 3; piece++) _piece(piece),
            ],
          ),
        ),
      ),
    );
  }

  Widget _piece(int piece) {
    final start = piece * .14;
    final value = reduceMotion
        ? 1.0
        : Curves.easeOutCubic.transform(
            ((progress - start) / .27).clamp(0.0, 1.0),
          );
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, piece == 1 ? 10 * (1 - value) : 0),
        child: ClipPath(
          clipper: SymbolPieceClipper(piece),
          child: BrandSymbol(size: size),
        ),
      ),
    );
  }
}
