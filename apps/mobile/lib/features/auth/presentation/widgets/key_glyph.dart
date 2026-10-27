import 'package:flutter/material.dart';

/// Key glyph from the canvas (24 grid: ring at 8,15 r4, shaft to the top
/// right with two teeth). Lucide's key points the other way.
class KeyGlyph extends StatelessWidget {
  const KeyGlyph({
    required this.color,
    required this.size,
    this.strokeWidth = 1.8,
    super.key,
  });

  final Color color;
  final double size;

  /// Stroke in the 24 grid.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _KeyPainter(color, strokeWidth),
    ),
  );
}

class _KeyPainter extends CustomPainter {
  const _KeyPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawCircle(const Offset(8, 15), 4, paint)
      ..drawLine(const Offset(10.8, 12.2), const Offset(20, 3), paint)
      ..drawLine(const Offset(16, 7), const Offset(19, 10), paint)
      ..drawLine(const Offset(14, 9), const Offset(16, 11), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_KeyPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
