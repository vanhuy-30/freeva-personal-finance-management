import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Ring of 16 with a short gap between slices and the total in the middle.
/// Decorative: the card gives the same numbers to screen readers.
class DonutChart extends StatelessWidget {
  const DonutChart({
    required this.fractions,
    required this.colors,
    required this.center,
    this.size = 112,
    super.key,
  });

  /// Each slice's share, in order; they add up to 1.
  final List<double> fractions;
  final List<Color> colors;
  final String center;
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
              painter: DonutPainter(fractions, colors, c.bgTrack),
            ),
            Padding(
              padding: const EdgeInsets.all(26),
              child: Text(
                center,
                maxLines: 1,
                softWrap: false,
                style: FreevaTypography.titleM.copyWith(
                  color: c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
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
  const DonutPainter(this.fractions, this.colors, this.track);

  final List<double> fractions;
  final List<Color> colors;
  final Color track;

  static const _stroke = 16.0;
  static const _gap = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint);
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
      old.track != track ||
      !_same(old.fractions, fractions) ||
      !_same(old.colors, colors);
}

bool _same<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
