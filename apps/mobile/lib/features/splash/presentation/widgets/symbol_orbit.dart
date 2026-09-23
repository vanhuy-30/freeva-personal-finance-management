import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SymbolOrbit extends CustomPainter {
  const SymbolOrbit(this.opacity);

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromCenter(
      center: Offset(size.width * .51, size.height * .50),
      width: size.width * .70,
      height: size.height * .76,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppColors.surface.withAlpha(0),
          AppColors.surface.withAlpha((opacity * .35 * 255).round()),
          AppColors.surface.withAlpha(0),
        ],
      ).createShader(bounds);
    canvas.save();
    canvas.translate(bounds.center.dx, bounds.center.dy);
    canvas.rotate(.35);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);
    canvas.drawArc(bounds, math.pi * .94, math.pi * .60, false, paint);
    canvas.drawArc(bounds, math.pi * .02, math.pi * .60, false, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(SymbolOrbit oldDelegate) => opacity != oldDelegate.opacity;
}
