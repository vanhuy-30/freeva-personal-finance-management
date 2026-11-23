import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Running net cash flow of a period: a line and its area against a dashed
/// zero line, with the axis on the right (highest, zero, lowest, and where
/// the line ends). The axis always holds zero, so a period that only spent
/// hangs below it and one that only earned climbs above it.
///
/// [values] are the running totals, oldest first, in minor units; they are
/// turned into drawing coordinates here and nowhere else. The labels are
/// computed by the caller so the painter stays free of l10n and money rules.
class CashflowChart extends StatelessWidget {
  const CashflowChart({
    required this.values,
    required this.highLabel,
    required this.lowLabel,
    required this.endLabel,
    required this.zeroLabel,
    required this.firstLabel,
    required this.lastLabel,
    required this.semanticsLabel,
    this.markerIndex,
    super.key,
  });

  final List<BigInt> values;

  /// Axis labels; null for a bound that is zero itself or that the end label covers.
  final String? highLabel;
  final String? lowLabel;
  final String endLabel;
  final String zeroLabel;
  final String firstLabel;
  final String lastLabel;
  final String semanticsLabel;

  /// Index of the point to mark as the biggest income, if any.
  final int? markerIndex;

  static const double plotHeight = 124;
  static const double _top = 14;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final last = values.isEmpty ? BigInt.zero : values.last;
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) => CustomPaint(
          size: Size(box.maxWidth, _top + plotHeight + 24 * scale),
          painter: _CashflowPainter(
            values: [for (final v in values) v.toDouble()],
            high: values.fold(BigInt.zero, (a, b) => b > a ? b : a).toDouble(),
            low: values.fold(BigInt.zero, (a, b) => b < a ? b : a).toDouble(),
            negative: last.isNegative,
            gutter: 60.0 * scale,
            textScaler: MediaQuery.textScalerOf(context),
            font: FreevaTypography.label,
            highLabel: highLabel,
            lowLabel: lowLabel,
            endLabel: endLabel,
            zeroLabel: zeroLabel,
            firstLabel: firstLabel,
            lastLabel: lastLabel,
            markerIndex: markerIndex,
            line: last.isNegative ? c.statusDanger : c.data1,
            area: (last.isNegative ? c.statusDanger : c.data1).withValues(
              alpha: 0.10,
            ),
            grid: c.borderDivider,
            zero: c.textPrimary.withValues(alpha: 0.65),
            ink: c.textPrimary,
            soft: c.textSecondary,
            marker: c.moneyIncome,
            halo: c.bgSurface,
          ),
        ),
      ),
    );
  }
}

class _CashflowPainter extends CustomPainter {
  _CashflowPainter({
    required this.values,
    required this.high,
    required this.low,
    required this.negative,
    required this.gutter,
    required this.textScaler,
    required this.font,
    required this.highLabel,
    required this.lowLabel,
    required this.endLabel,
    required this.zeroLabel,
    required this.firstLabel,
    required this.lastLabel,
    required this.markerIndex,
    required this.line,
    required this.area,
    required this.grid,
    required this.zero,
    required this.ink,
    required this.soft,
    required this.marker,
    required this.halo,
  });

  final List<double> values;
  final double high;
  final double low;
  final bool negative;
  final double gutter;
  final TextScaler textScaler;

  /// The app's label style, so the axis uses the app font like every other text.
  final TextStyle font;
  final String? highLabel;
  final String? lowLabel;
  final String endLabel;
  final String zeroLabel;
  final String firstLabel;
  final String lastLabel;
  final int? markerIndex;
  final Color line;
  final Color area;
  final Color grid;
  final Color zero;
  final Color ink;
  final Color soft;
  final Color marker;
  final Color halo;

  TextPainter _text(String text, Color color, {bool bold = false}) =>
      TextPainter(
        text: TextSpan(
          text: text,
          style: font.copyWith(
            fontSize: bold ? 11 : 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const left = 2.0;
    final right = math.max(left + 1, size.width - gutter);
    const top = CashflowChart._top;
    const height = CashflowChart.plotHeight;
    final span = math.max(1.0, high - low);
    double y(double v) => top + height - height * (v - low) / span;
    double x(int i) => values.length == 1
        ? right
        : left + (right - left) * i / (values.length - 1);
    final zeroY = y(0);

    void rule(double at, Paint paint) =>
        canvas.drawLine(Offset(left, at), Offset(right + 4, at), paint);
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    if (high > 0) rule(y(high), gridPaint);
    if (low < 0) rule(y(low), gridPaint);

    final path = Path()..moveTo(x(0), zeroY);
    for (var i = 0; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    path
      ..lineTo(x(values.length - 1), zeroY)
      ..close();
    canvas.drawPath(path, Paint()..color = area);

    final stroke = Path()..moveTo(x(0), y(values.first));
    for (var i = 1; i < values.length; i++) {
      stroke.lineTo(x(i), y(values[i]));
    }
    canvas.drawPath(
      stroke,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Zero line on top of the area, dashed and darker than the grid.
    final dash = Paint()
      ..color = zero
      ..strokeWidth = 1.2;
    for (var dx = left; dx < right + 4; dx += 9) {
      canvas.drawLine(
        Offset(dx, zeroY),
        Offset(math.min(dx + 5, right + 4), zeroY),
        dash,
      );
    }

    void dot(int i, Color color, double r) {
      final at = Offset(x(i), y(values[i]));
      canvas.drawCircle(at, r + 2, Paint()..color = halo);
      canvas.drawCircle(at, r, Paint()..color = color);
    }

    final mark = markerIndex;
    if (mark != null && mark >= 0 && mark < values.length - 1) {
      dot(mark, marker, 4.5);
    }
    dot(values.length - 1, line, 5);

    // Axis on the right. Each label is nudged so none lands on another.
    final taken = <double>[];
    double place(TextPainter label, double centre) {
      var at = centre;
      for (final other in taken) {
        if ((at - other).abs() < label.height) {
          at = other + (at >= other ? 1 : -1) * label.height;
        }
      }
      taken.add(at);
      return at - label.height / 2;
    }

    void axis(TextPainter label, double centre) {
      label.paint(canvas, Offset(right + 8, place(label, centre)));
    }

    axis(_text(zeroLabel, ink, bold: true), zeroY);
    axis(_text(endLabel, negative ? line : ink, bold: true), y(values.last));
    if (highLabel != null && high > 0) axis(_text(highLabel!, soft), y(high));
    if (lowLabel != null && low < 0) axis(_text(lowLabel!, soft), y(low));

    const base = top + height + 8;
    final first = _text(firstLabel, soft);
    first.paint(canvas, const Offset(left, base));
    final end = _text(lastLabel, soft);
    end.paint(
      canvas,
      Offset(math.max(first.width + 8, right - end.width), base),
    );
  }

  @override
  bool shouldRepaint(_CashflowPainter old) =>
      old.values != values ||
      old.high != high ||
      old.low != low ||
      old.endLabel != endLabel ||
      old.firstLabel != firstLabel ||
      old.lastLabel != lastLabel ||
      old.markerIndex != markerIndex ||
      old.line != line ||
      old.gutter != gutter ||
      old.textScaler != textScaler ||
      old.font != font;
}
