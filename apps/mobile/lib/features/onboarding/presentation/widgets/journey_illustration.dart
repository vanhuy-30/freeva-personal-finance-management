import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Hoàn tất (board ObDone): a dotted path up a mountain to a flag, three
/// coins along the way, a sun and a few sparkles. Decorative, so screen
/// readers skip it. Drawn from the canvas SVG (viewBox 350×300).
class JourneyIllustration extends StatelessWidget {
  const JourneyIllustration({super.key});

  static const Size size = Size(350, 300);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox.fromSize(
        size: size,
        child: CustomPaint(
          painter: _JourneyPainter(
            glow: c.tintBlue,
            subtle: c.bgSubtle,
            canvas: c.bgCanvas,
            backHill: c.bgWash,
            hill: c.data4,
            sun: c.statusWarningBg,
            coin: c.statusWarning,
            pole: c.textPrimary,
            flag: c.actionPrimary,
            path: c.bgSurface,
            sparkles: [c.data2, c.data3, c.data1],
          ),
        ),
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  const _JourneyPainter({
    required this.glow,
    required this.subtle,
    required this.canvas,
    required this.backHill,
    required this.hill,
    required this.sun,
    required this.coin,
    required this.pole,
    required this.flag,
    required this.path,
    required this.sparkles,
  });

  final Color glow;
  final Color subtle;
  final Color canvas;
  final Color backHill;
  final Color hill;
  final Color sun;
  final Color coin;
  final Color pole;
  final Color flag;
  final Color path;
  final List<Color> sparkles;

  @override
  void paint(Canvas c, Size size) {
    const view = JourneyIllustration.size;
    final scale = (size.width / view.width).clamp(
      0.0,
      size.height / view.height,
    );
    c
      ..save()
      ..translate(
        (size.width - view.width * scale) / 2,
        (size.height - view.height * scale) / 2,
      )
      ..scale(scale);

    // Soft round glow behind everything.
    const glowCenter = Offset(175, 150);
    c.drawCircle(
      glowCenter,
      150,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.1),
          radius: 0.55,
          colors: [glow, subtle, canvas],
          stops: const [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: 150)),
    );
    c.drawCircle(const Offset(268, 70), 24, Paint()..color = sun);

    // Back range, then the main mountain fading from the hill tone.
    c.drawPath(
      Path()
        ..moveTo(18, 262)
        ..lineTo(118, 150)
        ..lineTo(168, 196)
        ..lineTo(238, 112)
        ..lineTo(332, 262)
        ..close(),
      Paint()..color = backHill,
    );
    final mountain = Path()
      ..moveTo(0, 290)
      ..lineTo(112, 186)
      ..lineTo(175, 96)
      ..lineTo(250, 182)
      ..lineTo(350, 290)
      ..close();
    c.drawPath(
      mountain,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [hill, backHill],
        ).createShader(const Rect.fromLTWH(0, 96, 350, 194)),
    );
    // Snow cap.
    c.drawPath(
      Path()
        ..moveTo(175, 96)
        ..lineTo(193, 122)
        ..lineTo(182, 118)
        ..lineTo(175, 128)
        ..lineTo(168, 118)
        ..lineTo(157, 122)
        ..close(),
      Paint()..color = canvas,
    );

    // Dotted trail: SVG "M58 286 C108 270,88 236,132 226 S196 200,170 172
    // S162 132,175 104" (S reflects the previous control point).
    final trail = Path()
      ..moveTo(58, 286)
      ..cubicTo(108, 270, 88, 236, 132, 226)
      ..cubicTo(176, 216, 196, 200, 170, 172)
      ..cubicTo(144, 144, 162, 132, 175, 104);
    final dot = Paint()..color = path;
    for (final metric in trail.computeMetrics()) {
      for (double d = 0; d <= metric.length; d += 12) {
        final at = metric.getTangentForOffset(d);
        if (at != null) c.drawCircle(at.position, 2.5, dot);
      }
    }

    // Flag on the peak.
    c.drawLine(
      const Offset(175, 100),
      const Offset(175, 52),
      Paint()
        ..color = pole
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      Path()
        ..moveTo(176, 53)
        ..lineTo(208, 62)
        ..lineTo(176, 72)
        ..close(),
      Paint()..color = flag,
    );

    // Coins along the trail.
    final ring = Paint()
      ..color = coin
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final at in const [
      Offset(96, 258),
      Offset(138, 224),
      Offset(178, 182),
    ]) {
      c
        ..drawCircle(at, 10, Paint()..color = sun)
        ..drawCircle(at, 10, ring)
        ..drawCircle(at, 3, Paint()..color = coin);
    }

    // Four-point sparkles.
    _sparkle(c, const Offset(86, 112), 11, sparkles[0]);
    _sparkle(c, const Offset(286, 150), 8, sparkles[1]);
    _sparkle(c, const Offset(232, 36), 7, sparkles[2]);

    // Fade the foot of the mountain into the page.
    const fade = Rect.fromLTWH(0, 232, 350, 68);
    c.drawRect(
      fade,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [canvas.withValues(alpha: 0), canvas],
        ).createShader(fade),
    );
    c.restore();
  }

  /// SVG "l3 8 8 3 -8 3 -3 8 -3 -8 -8 -3 8 -3Z" scaled to [r]: top at
  /// [top], arms reaching r across.
  void _sparkle(Canvas c, Offset top, double r, Color color) {
    final k = r / 11;
    final p = Path()..moveTo(top.dx, top.dy);
    for (final (dx, dy) in const [
      (3.0, 8.0),
      (8.0, 3.0),
      (-8.0, 3.0),
      (-3.0, 8.0),
      (-3.0, -8.0),
      (-8.0, -3.0),
      (8.0, -3.0),
    ]) {
      p.relativeLineTo(dx * k, dy * k);
    }
    c.drawPath(p..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_JourneyPainter old) =>
      old.glow != glow ||
      old.hill != hill ||
      old.flag != flag ||
      old.canvas != canvas ||
      old.pole != pole;
}
