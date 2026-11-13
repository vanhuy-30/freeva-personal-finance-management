import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// S.2 bar, 10 high: spent so far solid, the rest of the forecast hatched,
/// and a 2 wide budget mark. Scaled to the larger of forecast and budget;
/// no mark without a budget.
class SpendForecastBar extends StatelessWidget {
  const SpendForecastBar({
    required this.spentMinor,
    required this.forecastMinor,
    required this.budgetMinor,
    super.key,
  });

  final BigInt spentMinor;
  final BigInt forecastMinor;
  final BigInt? budgetMinor;

  static const _height = 10.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final budget = budgetMinor;
    var top = forecastMinor;
    if (budget != null && budget > top) top = budget;
    if (spentMinor > top) top = spentMinor;
    double share(BigInt v) =>
        top == BigInt.zero ? 0 : (v / top).clamp(0, 1).toDouble();
    final spent = share(spentMinor);
    final forecast = math.max(spent, share(forecastMinor));
    // Board: #B9C8F0 / #DCE4FA stripes; the darker one is the primary over
    // the light tint, so both follow the theme.
    final light = c.dataMuted;
    final dark = Color.alphaBlend(
      c.actionPrimary.withValues(alpha: 0.25),
      light,
    );
    const round = Radius.circular(FreevaRadius.full);
    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.borderDivider,
                    borderRadius: BorderRadius.circular(FreevaRadius.full),
                  ),
                ),
              ),
              if (forecast > spent)
                Positioned(
                  left: w * spent,
                  width: w * (forecast - spent),
                  top: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.horizontal(
                      left: spent == 0 ? round : Radius.zero,
                      right: round,
                    ),
                    child: CustomPaint(
                      painter: _HatchPainter(light: light, dark: dark),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                width: w * spent,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.actionPrimary,
                    borderRadius: BorderRadius.horizontal(
                      left: round,
                      right: forecast > spent ? Radius.zero : round,
                    ),
                  ),
                ),
              ),
              if (budget != null)
                Positioned(
                  left: (w * share(budget)).clamp(0, w - 2),
                  top: -4,
                  width: 2,
                  height: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.textPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 135° stripes, 4 dark then 4 light, measured across the stripes.
class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.light, required this.dark});

  final Color light;
  final Color dark;

  static const _band = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = light);
    final paint = Paint()
      ..color = dark
      ..strokeWidth = _band;
    const step = 2 * _band * math.sqrt2;
    final h = size.height;
    // Stripes run "/": the CSS gradient goes toward the bottom right.
    for (var x = -h; x < size.width + h; x += step) {
      final start = x + _band * math.sqrt1_2;
      canvas.drawLine(Offset(start - h, h), Offset(start, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) =>
      old.light != light || old.dark != dark;
}
