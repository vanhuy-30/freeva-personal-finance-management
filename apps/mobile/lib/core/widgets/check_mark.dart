import 'package:flutter/material.dart';

/// Board check glyph (`M5 12l5 5L20 7` on a 24 grid) drawn with a heavy
/// stroke, for small ticks where the 1.75 icon font reads too thin.
class CheckMark extends StatelessWidget {
  const CheckMark({
    required this.color,
    this.size = 12,
    this.strokeWidth = 3.2,
    super.key,
  });

  final Color color;

  /// Box size in logical pixels.
  final double size;

  /// Stroke width on the 24-unit grid (scaled with [size]).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _CheckPainter(color, strokeWidth),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path()
      ..moveTo(5 * k, 12 * k)
      ..lineTo(10 * k, 17 * k)
      ..lineTo(20 * k, 7 * k);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
