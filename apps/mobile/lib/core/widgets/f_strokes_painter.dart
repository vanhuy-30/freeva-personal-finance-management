import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The three strokes of the Freeva "F", drawn on a 64 box. `t` (0–1, one
/// 3 s cycle) drifts each stroke out of phase; t = 0 is the static frame.
class FStrokesPainter extends CustomPainter {
  const FStrokesPainter({required this.colors, required this.t});

  /// Top, middle, bottom stroke colours.
  final List<Color> colors;
  final double t;

  static Path _top() => Path()
    ..moveTo(18, 30)
    ..cubicTo(18, 23, 24, 20, 46, 18)
    ..cubicTo(44, 25, 38, 28, 26, 29)
    ..cubicTo(22, 29, 19, 30, 18, 33)
    ..close();

  static Path _middle() => Path()
    ..moveTo(20, 39)
    ..cubicTo(20, 35, 25, 33, 40, 32)
    ..cubicTo(38, 38, 33, 40, 25, 41)
    ..cubicTo(22, 41, 21, 42, 20, 44)
    ..close();

  static Path _bottom() => Path()
    ..moveTo(21, 48)
    ..cubicTo(22, 45, 25, 44, 30, 44)
    ..cubicTo(29, 49, 26, 52, 22, 52)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);
    final paths = [_top(), _middle(), _bottom()];
    for (var i = 0; i < paths.length; i++) {
      final phase = (t + i / 3) * 2 * math.pi;
      final dx = t == 0 ? 0.0 : math.sin(phase) * 1.6;
      final dy = t == 0 ? 0.0 : math.cos(phase) * 1.2;
      canvas.drawPath(
        paths[i].shift(Offset(dx, dy)),
        Paint()..color = colors[i],
      );
    }
  }

  @override
  bool shouldRepaint(FStrokesPainter old) => old.t != t || old.colors != colors;
}

/// Static empty-state art on a 120×112 box: a ground shadow and the three
/// F bars (stem, tilted top bar, middle bar). Colours come from the caller so
/// dark mode can swap them.
class FStrokesIllustrationPainter extends CustomPainter {
  const FStrokesIllustrationPainter({
    required this.ground,
    required this.stem,
    required this.top,
    required this.middle,
  });

  final Color ground;
  final Color stem;
  final Color top;
  final Color middle;

  static RRect _bar(double x, double y, double w, double h) =>
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(8),
      );

  static void _rotated(
    Canvas canvas,
    RRect bar,
    double degrees,
    Offset pivot,
    Paint paint,
  ) {
    canvas
      ..save()
      ..translate(pivot.dx, pivot.dy)
      ..rotate(degrees * math.pi / 180)
      ..translate(-pivot.dx, -pivot.dy)
      ..drawRRect(bar, paint)
      ..restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 112);
    canvas
      ..drawOval(
        Rect.fromCenter(center: const Offset(60, 102), width: 68, height: 10),
        Paint()..color = ground,
      )
      ..drawRRect(_bar(38, 14, 16, 78), Paint()..color = stem);
    _rotated(
      canvas,
      _bar(46, 8, 48, 16),
      -6,
      const Offset(70, 16),
      Paint()..color = top,
    );
    _rotated(
      canvas,
      _bar(50, 44, 34, 16),
      4,
      const Offset(67, 52),
      Paint()..color = middle,
    );
  }

  @override
  bool shouldRepaint(FStrokesIllustrationPainter old) =>
      old.ground != ground ||
      old.stem != stem ||
      old.top != top ||
      old.middle != middle;
}
