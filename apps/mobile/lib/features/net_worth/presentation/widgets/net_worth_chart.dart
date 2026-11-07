import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/compact_money.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/net_worth_history.dart';
import 'net_worth_labels.dart';

/// Net worth over a window as one line over a soft area. Past points are
/// hollow dots, the latest is filled with a halo. Touching or dragging picks
/// the nearest point. Needs two points; the page hides it otherwise.
class NetWorthChart extends StatelessWidget {
  const NetWorthChart({
    required this.series,
    required this.digits,
    required this.hidden,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final NetWorthSeries series;
  final int digits;
  final bool hidden;

  /// Index of the touched point; null means the latest.
  final int? selected;
  final ValueChanged<int?> onSelect;

  static const height = 170.0;
  static const _labelHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final units = CompactUnits(
      thousand: s.reportUnitThousand,
      million: s.reportUnitMillion,
      billion: s.reportUnitBillion,
    );
    final points = series.points;
    String compact(BigInt v) => compactMoney(v, digits, locale, units);
    final first = points.first;
    final last = points.last;
    final label = s.netWorthChartSemantics(
      netWorthRangeLabel(s, series.window),
      hidden ? '' : compact(first.netWorthMinor),
      hidden ? '' : compact(last.netWorthMinor),
    );
    final labelStyle = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // Up to six evenly spaced x labels.
    final step = (points.length / 6).ceil().clamp(1, points.length);
    final labelIndexes = {for (var i = points.length - 1; i >= 0; i -= step) i};
    return Semantics(
      container: true,
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = box.maxWidth;
            final geometry = NetWorthGeometry(
              values: [for (final p in points) p.netWorthMinor],
              width: width,
              height: height,
            );
            void pick(Offset local) => onSelect(geometry.nearest(local.dx));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) => pick(d.localPosition),
                  onHorizontalDragStart: (d) => pick(d.localPosition),
                  onHorizontalDragUpdate: (d) => pick(d.localPosition),
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: _NetWorthPainter(
                      geometry: geometry,
                      selected: selected ?? points.length - 1,
                      line: c.actionPrimary,
                      area: c.actionPrimary.withValues(alpha: 0.1),
                      surface: c.bgSurface,
                    ),
                  ),
                ),
                SizedBox(
                  height: _labelHeight * scale.clamp(1, 2),
                  width: width,
                  child: Stack(
                    children: [
                      for (final i in labelIndexes)
                        Positioned(
                          left: (geometry.x(i) - 24).clamp(0, width - 48),
                          width: 48,
                          child: Text(
                            netWorthAxisLabel(s, series.window, points[i].asOf),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: labelStyle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Maps values to canvas points; shared by the painter and the touch
/// handler so both agree.
class NetWorthGeometry {
  NetWorthGeometry({
    required this.values,
    required this.width,
    required this.height,
  }) {
    var low = values.first;
    var high = values.first;
    for (final v in values) {
      if (v < low) low = v;
      if (v > high) high = v;
    }
    _low = low;
    _span = high - low;
  }

  static const inset = 12.0;
  static const _vertical = 16.0;

  final List<BigInt> values;
  final double width;
  final double height;
  late final BigInt _low;
  late final BigInt _span;

  double x(int i) => values.length == 1
      ? width / 2
      : inset + (width - 2 * inset) * i / (values.length - 1);

  double y(int i) {
    if (_span == BigInt.zero) return height / 2;
    // BigInt ratio without double overflow: scale to permille first.
    final ratio = ((values[i] - _low) * BigInt.from(10000) ~/ _span).toInt();
    return height - _vertical - (height - 2 * _vertical) * ratio / 10000;
  }

  /// Index of the point closest to [dx].
  int nearest(double dx) {
    var best = 0;
    var gap = double.infinity;
    for (var i = 0; i < values.length; i++) {
      final d = (x(i) - dx).abs();
      if (d < gap) {
        gap = d;
        best = i;
      }
    }
    return best;
  }
}

class _NetWorthPainter extends CustomPainter {
  _NetWorthPainter({
    required this.geometry,
    required this.selected,
    required this.line,
    required this.area,
    required this.surface,
  });

  final NetWorthGeometry geometry;
  final int selected;
  final Color line;
  final Color area;
  final Color surface;

  @override
  void paint(Canvas canvas, Size size) {
    final n = geometry.values.length;
    final path = Path()..moveTo(geometry.x(0), geometry.y(0));
    for (var i = 1; i < n; i++) {
      path.lineTo(geometry.x(i), geometry.y(i));
    }
    final fill = Path.from(path)
      ..lineTo(geometry.x(n - 1), size.height)
      ..lineTo(geometry.x(0), size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = area);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = line,
    );
    // Hollow dots only while they stay readable.
    if (n <= 12) {
      for (var i = 0; i < n; i++) {
        if (i == n - 1 || i == selected) continue;
        final at = Offset(geometry.x(i), geometry.y(i));
        canvas.drawCircle(at, 3, Paint()..color = surface);
        canvas.drawCircle(
          at,
          3,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = line,
        );
      }
    }
    final at = Offset(geometry.x(selected), geometry.y(selected));
    canvas.drawCircle(at, 7, Paint()..color = line.withValues(alpha: 0.18));
    canvas.drawCircle(at, 4.5, Paint()..color = line);
  }

  @override
  bool shouldRepaint(_NetWorthPainter old) =>
      !listEquals(old.geometry.values, geometry.values) ||
      old.geometry.width != geometry.width ||
      old.selected != selected ||
      old.line != line ||
      old.area != area ||
      old.surface != surface;
}
