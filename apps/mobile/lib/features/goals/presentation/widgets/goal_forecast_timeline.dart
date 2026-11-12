import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import 'goal_forecast_text.dart';

/// T.1 timeline, 62 high: a 4 track, on-time part in the primary colour,
/// the late part dashed in the warning colour, 14 dots with 3 rings and a
/// "label / MM/yyyy" under each.
class GoalForecastTimeline extends StatelessWidget {
  const GoalForecastTimeline({required this.timeline, super.key});

  final GoalTimeline timeline;

  static const _dot = 14.0;
  static const _labelWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 4, 7, 0),
      child: SizedBox(
        height: 62,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 5,
                  height: 4,
                  child: CustomPaint(
                    painter: _TrackPainter(
                      solid: timeline.solid,
                      late: timeline.late,
                      track: c.borderDivider,
                      onTime: c.actionPrimary,
                      lateColor: c.statusWarning,
                    ),
                  ),
                ),
                for (final mark in timeline.marks) ...[
                  Positioned(
                    left: w * mark.at - _dot / 2,
                    top: 0,
                    width: _dot,
                    height: _dot,
                    child: _Dot(look: _look(c, mark.kind)),
                  ),
                  Positioned(
                    left: switch (mark.at) {
                      0 => 0,
                      1 => w - _labelWidth,
                      final at => w * at - _labelWidth / 2,
                    },
                    width: _labelWidth,
                    top: 24,
                    child: _Label(
                      title: switch (mark.kind) {
                        GoalMarkKind.today => s.goalForecastToday,
                        GoalMarkKind.due => s.goalForecastDue,
                        GoalMarkKind.expected => s.goalForecastWhen,
                      },
                      month: mark.month,
                      align: switch (mark.at) {
                        0 => CrossAxisAlignment.start,
                        1 => CrossAxisAlignment.end,
                        _ => CrossAxisAlignment.center,
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// (fill, ring) of a dot.
  (Color, Color) _look(FreevaColors c, GoalMarkKind kind) => switch (kind) {
    GoalMarkKind.today => (c.actionPrimary, c.tintBlue),
    GoalMarkKind.due => (c.cardBg, c.actionPrimary),
    GoalMarkKind.expected when timeline.late => (
      c.statusWarning,
      c.statusWarningBg,
    ),
    GoalMarkKind.expected => (c.statusSuccess, c.statusSuccessBg),
  };
}

class _Dot extends StatelessWidget {
  const _Dot({required this.look});

  final (Color, Color) look;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: look.$1,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: look.$2, spreadRadius: 3)],
    ),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.title, required this.month, required this.align});

  final String title;
  final String month;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          style: FreevaTypography.label.copyWith(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        Text(
          month,
          maxLines: 1,
          style: FreevaTypography.bodyS.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
            color: c.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.solid,
    required this.late,
    required this.track,
    required this.onTime,
    required this.lateColor,
  });

  final double solid;
  final bool late;
  final Color track;
  final Color onTime;
  final Color lateColor;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final radius = Radius.circular(h / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, radius),
      Paint()..color = track,
    );
    final split = size.width * solid;
    if (split > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, split, h), radius),
        Paint()..color = onTime,
      );
    }
    if (!late) return;
    final paint = Paint()..color = lateColor;
    // Board: 6 on, 4 off; only the far end is rounded.
    canvas.clipRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(split, 0, size.width, h), radius),
    );
    for (var x = split; x < size.width; x += 10) {
      canvas.drawRect(
        Rect.fromLTRB(x, 0, math.min(x + 6, size.width), h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.solid != solid ||
      old.late != late ||
      old.track != track ||
      old.onTime != onTime ||
      old.lateColor != lateColor;
}
