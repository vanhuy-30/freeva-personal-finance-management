import 'package:flutter/material.dart';

/// Pill bar with a concave notch around the centre + button. The notch is a
/// real cut-out (path difference), not a ring painted in the page colour.
class NavNotchPainter extends CustomPainter {
  const NavNotchPainter({
    required this.color,
    required this.shadows,
    required this.notchCenterY,
    required this.notchRadius,
  });

  final Color color;
  final List<BoxShadow> shadows;

  /// Centre of the + button, in bar coordinates (negative = above the bar).
  final double notchCenterY;
  final double notchRadius;

  @visibleForTesting
  Path shape(Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, notchCenterY),
          radius: notchRadius,
        ),
      );
    return Path.combine(PathOperation.difference, bar, notch);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = this.shape(size);
    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);
      canvas.drawPath(shape.shift(shadow.offset), paint);
    }
    canvas.drawPath(shape, Paint()..color = color);
  }

  @override
  bool shouldRepaint(NavNotchPainter old) =>
      old.color != color ||
      old.notchCenterY != notchCenterY ||
      old.notchRadius != notchRadius ||
      !_sameShadows(old.shadows, shadows);

  static bool _sameShadows(List<BoxShadow> a, List<BoxShadow> b) =>
      a.length == b.length &&
      [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
}
