import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Ring of 16 (radius 52 in a 128 box) with a short gap between slices,
/// "Tổng chi" and the total in the middle. Decorative: the card gives the
/// same numbers to screen readers.
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.fractions,
    required this.colors,
    required this.center,
    this.label,
    this.size = 128,
    super.key,
  });

  /// Each slice's share, in order; they add up to 1.
  final List<double> fractions;
  final List<Color> colors;
  final String center;

  /// Small line above [center] ("Tổng chi").
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: DonutPainter(fractions, colors),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        maxLines: 1,
                        softWrap: false,
                        style: FreevaTypography.label.copyWith(
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    Text(
                      center,
                      maxLines: 1,
                      softWrap: false,
                      style: FreevaTypography.titleM.copyWith(
                        height: 1.2,
                        color: c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DonutPainter extends CustomPainter {
  const DonutPainter(this.fractions, this.colors);

  final List<double> fractions;
  final List<Color> colors;

  static const _stroke = 16.0;

  /// About 2 pt of card showing between slices.
  static const _gap = 0.038;

  @override
  void paint(Canvas canvas, Size size) {
    // Radius 52 in a 128 box: the ring ends 4 inside the edge.
    final radius = size.shortestSide / 2 * 52 / 64;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    var start = -math.pi / 2;
    final gap = fractions.length > 1 ? _gap : 0.0;
    for (var i = 0; i < fractions.length; i++) {
      final sweep = math.max(fractions[i] * math.pi * 2 - gap, 0.01);
      canvas.drawArc(
        rect,
        start + gap / 2,
        sweep,
        false,
        paint..color = colors[i],
      );
      start += fractions[i] * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(DonutPainter old) =>
      !_same(old.fractions, fractions) || !_same(old.colors, colors);
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
