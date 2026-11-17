import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// The picture of every empty state: a blank page floating in a soft halo,
/// with a coin, a dot and a sparkle drifting around it. It moves for three
/// slow turns, then rests (no endless animation, so a screen left open does
/// not keep redrawing); with reduced motion it never moves.
class EmptyIllustration extends StatefulWidget {
  const EmptyIllustration({super.key});

  /// Side of the square it is drawn in.
  static const size = 132.0;

  @override
  State<EmptyIllustration> createState() => _EmptyIllustrationState();
}

class _EmptyIllustrationState extends State<EmptyIllustration>
    with SingleTickerProviderStateMixin {
  static const _turns = 3;
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200 * _turns),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.stop();
      _controller.value = 0;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: EmptyIllustration.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _EmptyPainter(
              colors: c,
              // 0..1 within one turn; the last turn ends where it started.
              t: (_controller.value * _turns) % 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPainter extends CustomPainter {
  _EmptyPainter({required this.colors, required this.t});

  final FreevaColors colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / EmptyIllustration.size;
    canvas.scale(k);
    final wave = math.sin(2 * math.pi * t);
    final c = colors;

    // Halo.
    canvas.drawCircle(const Offset(66, 68), 58, Paint()..color = c.tintBlue);

    // The page.
    canvas.save();
    canvas.translate(66, 70 + wave * 3);
    canvas.rotate((-6 + wave * 2) * math.pi / 180);
    final page = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-34, -42, 68, 84),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      page.shift(const Offset(0, 4)),
      Paint()
        ..color = c.tintBlueFg.withAlpha(28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(page, Paint()..color = c.bgSurface);
    canvas.drawRRect(
      page,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = c.borderDefault,
    );
    void bar(double y, double w, Color color) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-22, y, w, 7),
        const Radius.circular(3.5),
      ),
      Paint()..color = color,
    );
    bar(-24, 28, c.tintBlueFg.withAlpha(90));
    bar(-8, 44, c.bgSubtle);
    bar(8, 34, c.bgSubtle);
    bar(24, 40, c.bgSubtle);
    canvas.restore();

    // A coin, up and to the right.
    final coin = Offset(106, 32 - wave * 4);
    canvas.drawCircle(coin, 14, Paint()..color = c.tintViolet);
    canvas.drawCircle(
      coin,
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c.tintVioletFg.withAlpha(150),
    );
    canvas.drawCircle(coin, 5, Paint()..color = c.tintVioletFg.withAlpha(150));

    // A dot, low and to the left.
    canvas.drawCircle(
      Offset(20, 96 + wave * 3),
      6,
      Paint()..color = c.tintCyanFg.withAlpha(140),
    );

    // A sparkle that breathes.
    final glow = .55 + .45 * (0.5 + 0.5 * math.sin(2 * math.pi * t + 1));
    final star = Path()
      ..moveTo(26, 28)
      ..quadraticBezierTo(27.5, 36.5, 36, 38)
      ..quadraticBezierTo(27.5, 39.5, 26, 48)
      ..quadraticBezierTo(24.5, 39.5, 16, 38)
      ..quadraticBezierTo(24.5, 36.5, 26, 28)
      ..close();
    canvas.drawPath(
      star,
      Paint()..color = c.tintBlueFg.withAlpha((255 * glow).round()),
    );
  }

  @override
  bool shouldRepaint(_EmptyPainter old) => old.t != t || old.colors != colors;
}
