import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// The one card with the colour wash. Only on Overview, wallet detail and
/// the Welcome sample.
class WashSurface extends StatelessWidget {
  const WashSurface({
    required this.child,
    this.padding = const EdgeInsets.all(FreevaSpace.s5),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaComponent.balanceCardRadius);
    return ClipRRect(
      borderRadius: radius,
      child: CustomPaint(
        painter: _WashPainter(
          bg: c.balanceCardBg,
          topRight: c.balanceCardWashTopRight,
          bottomLeft: c.balanceCardWashBottomLeft,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Paints the two elliptical washes of the board: `120% 90% at 100% 0%`
/// (fade by 55%) and `90% 80% at 0% 100%` (fade by 60%).
class _WashPainter extends CustomPainter {
  const _WashPainter({
    required this.bg,
    required this.topRight,
    required this.bottomLeft,
  });

  final Color bg;
  final Color topRight;
  final Color bottomLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = bg);
    void ellipse(
      Color color,
      Offset center,
      double rx,
      double ry,
      double stop,
    ) {
      if (rx <= 0 || ry <= 0) return;
      canvas
        ..save()
        ..clipRect(bounds)
        ..translate(center.dx, center.dy)
        ..scale(rx, ry);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: [0, stop],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));
      canvas
        ..drawRect(const Rect.fromLTRB(-1, -1, 1, 1), paint)
        ..restore();
    }

    ellipse(
      topRight,
      Offset(size.width, 0),
      size.width * 1.2,
      size.height * .9,
      .55,
    );
    ellipse(
      bottomLeft,
      Offset(0, size.height),
      size.width * .9,
      size.height * .8,
      .6,
    );
  }

  @override
  bool shouldRepaint(_WashPainter old) =>
      old.bg != bg || old.topRight != topRight || old.bottomLeft != bottomLeft;
}

/// Small white-72% tile on the wash (income / expense of the month):
/// padding 10/12, label 12, value [valueStyle]; 55 high.
class WashStatTile extends StatelessWidget {
  const WashStatTile({required this.label, required this.value, super.key});

  /// Style for the value (15/600, line height 1.2).
  static final TextStyle valueStyle = FreevaTypography.titleM.copyWith(
    height: 1.2,
  );

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.bgSurface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(FreevaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: c.balanceCardFg,
            ),
          ),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );
  }
}
