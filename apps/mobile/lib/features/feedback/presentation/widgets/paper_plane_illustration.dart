import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Hand-drawn paper plane over a soft circle (MeFeedbackSent), 220×200.
class PaperPlaneIllustration extends StatelessWidget {
  const PaperPlaneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(220, 200),
        painter: _PlanePainter(
          circle: c.dataMuted,
          ground: c.borderDivider,
          paper: c.bgSurface,
          ink: c.textPrimary,
        ),
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  const _PlanePainter({
    required this.circle,
    required this.ground,
    required this.paper,
    required this.ink,
  });

  final Color circle;
  final Color ground;
  final Color paper;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 220, size.height / 200);
    canvas.drawCircle(const Offset(110, 96), 78, Paint()..color = circle);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 186), width: 92, height: 10),
      Paint()..color = ground,
    );
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final plane = Path()
      ..moveTo(44, 104)
      ..lineTo(170, 52)
      ..lineTo(132, 150)
      ..lineTo(110, 116)
      ..close();
    canvas
      ..drawPath(plane, Paint()..color = paper)
      ..drawPath(plane, stroke);
    final fold = Path()
      ..moveTo(170, 52)
      ..lineTo(110, 116)
      ..lineTo(104, 146)
      ..lineTo(120, 128);
    canvas.drawPath(fold, stroke);
    // Dotted trail: dash 2, gap 8 along the curve.
    final trail = Path()
      ..moveTo(30, 140)
      ..cubicTo(46, 132, 58, 136, 72, 128);
    for (final metric in trail.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 2), stroke);
      }
    }
    canvas.drawCircle(const Offset(178, 34), 4, Paint()..color = ink);
    canvas.drawCircle(
      const Offset(192, 58),
      2.5,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_PlanePainter old) =>
      old.circle != circle ||
      old.ground != ground ||
      old.paper != paper ||
      old.ink != ink;
}
