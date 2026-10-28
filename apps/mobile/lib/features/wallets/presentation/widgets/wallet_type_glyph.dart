import 'package:flutter/material.dart';

import '../../domain/wallet.dart';

/// Wallet type glyph drawn from the canvas paths (24 viewBox, round caps).
/// Lucide has no exact match: its landmark has a closed roof, banknote has
/// side dots and credit-card lacks the short number line.
class WalletTypeGlyph extends StatelessWidget {
  const WalletTypeGlyph({
    required this.type,
    required this.size,
    required this.color,
    super.key,
  });

  final WalletType type;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(type, color),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.type, this.color);

  final WalletType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    void box(double x, double y, double w, double h) => canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(3),
      ),
      paint,
    );
    switch (type) {
      case WalletType.bank:
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(12, 4)
            ..lineTo(21, 10),
          paint,
        );
        for (final x in const [5.0, 9.5, 14.5, 19.0]) {
          line(x, 10, x, 18);
        }
        line(3, 21, 21, 21);
      case WalletType.cash:
        box(2.5, 6, 19, 13);
        canvas.drawCircle(const Offset(12, 12.5), 2.5, paint);
      case WalletType.ewallet:
        box(6, 2.5, 12, 19);
        line(11, 18, 13, 18);
      case WalletType.credit:
        box(2.5, 5, 19, 14);
        line(2.5, 10, 21.5, 10);
        line(6, 15, 10, 15);
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.type != type || old.color != color;
}
