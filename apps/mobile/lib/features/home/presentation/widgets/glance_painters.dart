import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Progress ring with a round cap, an optional marker dot (for "today" in
/// the month) and a centred [child]. [value] and [marker] are 0–1.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.size,
    required this.stroke,
    required this.value,
    required this.color,
    required this.track,
    this.marker,
    this.markerColor,
    this.markerBorder,
    this.child,
    super.key,
  });

  final double size;
  final double stroke;
  final double value;
  final Color color;
  final Color track;
  final double? marker;
  final Color? markerColor;
  final Color? markerBorder;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _RingPainter(
        stroke: stroke,
        value: value.clamp(0, 1).toDouble(),
        color: color,
        track: track,
        marker: marker?.clamp(0, 1).toDouble(),
        markerColor: markerColor ?? color,
        markerBorder: markerBorder,
      ),
      child: Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.stroke,
    required this.value,
    required this.color,
    required this.track,
    required this.marker,
    required this.markerColor,
    required this.markerBorder,
  });

  final double stroke;
  final double value;
  final Color color;
  final Color track;
  final double? marker;
  final Color markerColor;
  final Color? markerBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, base..color = track);
    if (value > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        value * 2 * math.pi,
        false,
        base
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
    final at = marker;
    if (at != null) {
      final angle = -math.pi / 2 + at * 2 * math.pi;
      final dot = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (markerBorder != null) {
        canvas.drawCircle(dot, 5, Paint()..color = markerBorder!);
      }
      canvas.drawCircle(dot, 3.5, Paint()..color = markerColor);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.marker != marker ||
      old.color != color ||
      old.track != track ||
      old.markerColor != markerColor ||
      old.markerBorder != markerBorder ||
      old.stroke != stroke;
}

/// Faint line with a soft fill under it, oldest value on the left.
class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    required this.color,
    this.height = 34,
    super.key,
  });

  final List<BigInt> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _SparkPainter(values, color)),
  );
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.values, this.color);

  final List<BigInt> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final numbers = [for (final v in values) v.toDouble()];
    final low = numbers.reduce(math.min);
    final high = numbers.reduce(math.max);
    final span = high - low;
    const inset = 2.0;
    final usable = size.height - inset * 2;
    Offset at(int i) => Offset(
      size.width * i / (numbers.length - 1),
      span == 0
          ? size.height / 2
          : inset + usable * (1 - (numbers[i] - low) / span),
    );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < numbers.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: .12));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || !_same(old.values, values);

  static bool _same(List<BigInt> a, List<BigInt> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
