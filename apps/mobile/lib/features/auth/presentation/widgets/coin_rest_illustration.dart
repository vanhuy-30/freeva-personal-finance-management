import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Line drawing on Tạo tài khoản: a person sitting on a coin, arms up.
/// Decorative, so screen readers skip it. Drawn from the canvas SVG
/// (viewBox 260×216) so no SVG package is needed.
class CoinRestIllustration extends StatelessWidget {
  const CoinRestIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 300,
        height: 250,
        child: CustomPaint(
          painter: _CoinRestPainter(
            ink: c.textPrimary,
            paper: c.bgSurface,
            shirt: c.dataMuted,
          ),
        ),
      ),
    );
  }
}

class _CoinRestPainter extends CustomPainter {
  const _CoinRestPainter({
    required this.ink,
    required this.paper,
    required this.shirt,
  });

  final Color ink;
  final Color paper;
  final Color shirt;

  static const Size _view = Size(260, 216);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _view.width).clamp(
      0.0,
      size.height / _view.height,
    );
    canvas
      ..save()
      ..translate(
        (size.width - _view.width * scale) / 2,
        (size.height - _view.height * scale) / 2,
      )
      ..scale(scale);

    Paint line([double width = 2.4]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    Paint fill(Color color) => Paint()..color = color;
    void both(Path path, Color color, [double width = 2.4]) => canvas
      ..drawPath(path, fill(color))
      ..drawPath(path, line(width));
    Path lines(List<List<double>> segs) {
      final p = Path();
      for (final s in segs) {
        p
          ..moveTo(s[0], s[1])
          ..lineTo(s[2], s[3]);
      }
      return p;
    }

    // Sparkles and motion marks.
    canvas
      ..drawPath(
        lines([
          [44, 66, 44, 78],
          [38, 72, 50, 72],
          [222, 92, 222, 100],
          [218, 96, 226, 96],
          [80, 40, 73, 33],
          [77, 52, 68, 52],
          [80, 63, 73, 67],
        ]),
        line(2),
      )
      ..drawPath(
        _dashed(
          Path()
            ..moveTo(196, 50)
            ..quadraticBezierTo(176, 62, 186, 76),
          3,
          5,
        ),
        line(2),
      );

    // Paper plane.
    both(
      Path()
        ..moveTo(199, 46)
        ..lineTo(230, 32)
        ..lineTo(215, 59)
        ..lineTo(210, 49)
        ..close(),
      paper,
    );
    canvas.drawPath(
      lines([
        [210, 49, 230, 32],
      ]),
      line(),
    );

    // Hands and arms.
    for (final x in [92.0, 170.0]) {
      final hand = Path()
        ..addOval(Rect.fromCircle(center: Offset(x, 47), radius: 5));
      both(hand, paper);
    }
    canvas.drawPath(
      Path()
        ..moveTo(115, 92)
        ..quadraticBezierTo(99, 78, 93, 53)
        ..moveTo(145, 92)
        ..quadraticBezierTo(161, 78, 169, 53),
      line(),
    );

    // Shirt, neck, head, hair, face.
    both(
      Path()
        ..moveTo(111, 88)
        ..quadraticBezierTo(130, 81, 149, 88)
        ..lineTo(153, 124)
        ..quadraticBezierTo(130, 130, 107, 124)
        ..close(),
      shirt,
    );
    canvas.drawPath(
      lines([
        [130, 79, 130, 85],
      ]),
      line(),
    );
    both(
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(130, 63), radius: 16)),
      paper,
    );
    both(
      Path()
        ..moveTo(114, 61)
        ..cubicTo(112, 45, 124, 38, 132, 40)
        ..cubicTo(143, 38, 151, 47, 146, 61)
        ..cubicTo(143, 53, 138, 50, 131, 51)
        ..cubicTo(123, 50, 118, 54, 114, 61)
        ..close(),
      ink,
    );
    canvas
      ..drawCircle(const Offset(124, 65), 1.6, fill(ink))
      ..drawCircle(const Offset(136, 65), 1.6, fill(ink))
      ..drawPath(
        Path()
          ..moveTo(125, 71)
          ..quadraticBezierTo(130, 75, 135, 71),
        line(),
      );

    // Coin: dark edge, white face, inner rim.
    final edge = Path()
      ..moveTo(66, 156)
      ..quadraticBezierTo(130, 184, 194, 156)
      ..lineTo(194, 166)
      ..quadraticBezierTo(130, 194, 66, 166)
      ..close();
    both(edge, ink);
    both(_ellipse(130, 156, 64, 14), paper);
    canvas.drawPath(_ellipse(130, 156, 46, 8), line(1.8));

    // Legs over the coin.
    both(
      Path()
        ..moveTo(105, 124)
        ..quadraticBezierTo(86, 142, 110, 149)
        ..quadraticBezierTo(130, 153, 150, 149)
        ..quadraticBezierTo(174, 142, 155, 124),
      paper,
    );
    canvas
      ..drawPath(
        Path()
          ..moveTo(117, 142)
          ..quadraticBezierTo(130, 136, 143, 142),
        line(),
      )
      // Shadows on the ground.
      ..drawPath(_ellipse(84, 203, 12, 3), line(1.8))
      ..drawPath(_ellipse(180, 205, 10, 3), line(1.8))
      ..drawPath(_ellipse(130, 208, 6, 2), fill(ink))
      ..restore();
  }

  static Path _ellipse(double cx, double cy, double rx, double ry) => Path()
    ..addOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    );

  static Path _dashed(Path source, double dash, double gap) {
    final out = Path();
    for (final ui.PathMetric m in source.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += dash + gap) {
        out.addPath(m.extractPath(d, d + dash), Offset.zero);
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(_CoinRestPainter old) =>
      old.ink != ink || old.paper != paper || old.shirt != shirt;
}
