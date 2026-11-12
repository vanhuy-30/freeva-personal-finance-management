import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.g.dart';
import '../../domain/spending_forecast.dart';

/// Maps days and amounts to chart points; shared by the painter and the
/// labels laid over it so both agree. Board S.3: plot from x 14 to width−10,
/// y 24 (the larger of forecast and budget) down to 150 (zero).
class SpendChartGeometry {
  SpendChartGeometry._({
    required this.width,
    required this.days,
    required this.points,
    required this.forecastMinor,
    required this.budgetMinor,
    required this.top,
  });

  factory SpendChartGeometry.of(
    SpendingForecast f,
    SpendForecastPeriod? period,
    double width,
  ) {
    final start = period == null ? null : _utc(period.from);
    final points = <(int, BigInt)>[
      for (final (i, p) in f.cumulative.indexed)
        (
          start == null ? i : _utc(p.date).difference(start).inDays,
          p.spentMinor,
        ),
    ];
    final forecast = f.forecastMinor ?? f.spentMinor;
    var top = forecast;
    final budget = f.budgetLimitMinor;
    if (budget != null && budget > top) top = budget;
    for (final (_, v) in points) {
      if (v > top) top = v;
    }
    return SpendChartGeometry._(
      width: width,
      days: math.max(f.daysInPeriod, 2),
      points: points,
      forecastMinor: forecast,
      budgetMinor: budget,
      top: top,
    );
  }

  static const left = 14.0;
  static const _rightInset = 10.0;
  static const _plotTop = 24.0;
  static const bottom = 150.0;

  final double width;
  final int days;

  /// (day index from the first day, spent so far).
  final List<(int, BigInt)> points;
  final BigInt forecastMinor;
  final BigInt? budgetMinor;

  /// The amount drawn at the top of the plot.
  final BigInt top;

  double get right => width - _rightInset;

  /// Day index of the last known point: today.
  int get todayIndex => points.isEmpty ? 0 : points.last.$1;

  double x(int day) => left + (right - left) * day / (days - 1);

  double y(BigInt minor) => top == BigInt.zero
      ? bottom
      : bottom - (bottom - _plotTop) * (minor / top).clamp(0, 1).toDouble();

  Offset get today => points.isEmpty
      ? const Offset(left, bottom)
      : Offset(x(points.last.$1), y(points.last.$2));

  Offset get end => Offset(right, y(forecastMinor));

  static DateTime _utc(String day) => DateTime.parse('${day}T00:00:00Z');

  @override
  bool operator ==(Object other) =>
      other is SpendChartGeometry &&
      other.width == width &&
      other.days == days &&
      other.forecastMinor == forecastMinor &&
      other.budgetMinor == budgetMinor &&
      other.top == top &&
      _samePoints(other.points);

  bool _samePoints(List<(int, BigInt)> other) {
    if (other.length != points.length) return false;
    for (var i = 0; i < points.length; i++) {
      if (other[i] != points[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(width, days, forecastMinor, budgetMinor, top, points.length);
}

/// Theme colours the chart draws with.
class SpendChartColors {
  const SpendChartColors({
    required this.axis,
    required this.budget,
    required this.area,
    required this.line,
    required this.forecast,
    required this.surface,
  });

  factory SpendChartColors.of(FreevaColors c) => SpendChartColors(
    axis: c.borderDivider,
    budget: c.textPrimary,
    area: c.tintBlue,
    line: c.actionPrimary,
    forecast: c.statusDanger,
    surface: c.cardBg,
  );

  final Color axis;
  final Color budget;
  final Color area;
  final Color line;
  final Color forecast;
  final Color surface;

  @override
  bool operator ==(Object other) =>
      other is SpendChartColors &&
      other.axis == axis &&
      other.budget == budget &&
      other.area == area &&
      other.line == line &&
      other.forecast == forecast &&
      other.surface == surface;

  @override
  int get hashCode => Object.hash(axis, budget, area, line, forecast, surface);
}

/// Draws the lines of [SpendChartGeometry]; labels are widgets on top.
class SpendForecastPainter extends CustomPainter {
  const SpendForecastPainter({required this.geometry, required this.colors});

  final SpendChartGeometry geometry;
  final SpendChartColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    const bottom = SpendChartGeometry.bottom;
    canvas.drawLine(
      const Offset(SpendChartGeometry.left, bottom),
      Offset(g.right, bottom),
      Paint()
        ..color = colors.axis
        ..strokeWidth = 1,
    );
    final budget = g.budgetMinor;
    if (budget != null) {
      final y = g.y(budget);
      _dashed(
        canvas,
        Offset(SpendChartGeometry.left, y),
        Offset(g.right, y),
        Paint()
          ..color = colors.budget
          ..strokeWidth = 1.2,
        dash: 2,
        gap: 4,
      );
    }
    if (g.points.isNotEmpty) {
      final line = Path();
      for (final (i, (day, v)) in g.points.indexed) {
        final p = Offset(g.x(day), g.y(v));
        i == 0 ? line.moveTo(p.dx, p.dy) : line.lineTo(p.dx, p.dy);
      }
      final area = Path.from(line)
        ..lineTo(g.today.dx, bottom)
        ..lineTo(g.x(g.points.first.$1), bottom)
        ..close();
      canvas
        ..drawPath(area, Paint()..color = colors.area)
        ..drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = colors.line,
        );
    }
    final today = g.today;
    final end = g.end;
    if (end.dx > today.dx) {
      _dashed(
        canvas,
        today,
        end,
        Paint()
          ..color = colors.forecast
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
        dash: 5,
        gap: 5,
      );
      canvas
        ..drawCircle(end, 4, Paint()..color = colors.surface)
        ..drawCircle(
          end,
          4,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = colors.forecast,
        );
    }
    canvas
      ..drawCircle(today, 6, Paint()..color = colors.surface)
      ..drawCircle(today, 4, Paint()..color = colors.line);
  }

  static void _dashed(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    final delta = to - from;
    final length = delta.distance;
    if (length == 0) return;
    final unit = delta / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      final stop = math.min(d + dash, length);
      canvas.drawLine(from + unit * d, from + unit * stop, paint);
    }
  }

  @override
  bool shouldRepaint(SpendForecastPainter old) =>
      old.geometry != geometry || old.colors != colors;
}
