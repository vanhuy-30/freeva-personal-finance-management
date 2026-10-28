import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// "Đã đồng bộ hết": line-drawn cloud with a tick, the title and when the
/// last sync happened, centred under the top bar.
class SyncDoneView extends StatelessWidget {
  const SyncDoneView({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 110),
        child: Column(
          children: [
            const SyncDoneIllustration(),
            const SizedBox(height: FreevaSpace.s6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: FreevaTypography.titleS.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: FreevaSpace.s2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cloud with a tick on a soft blue disc (canvas SVG, viewBox 200×170).
/// Decorative, so screen readers skip it.
class SyncDoneIllustration extends StatelessWidget {
  const SyncDoneIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: SizedBox(
        width: 200,
        height: 170,
        child: CustomPaint(
          painter: _CloudPainter(
            disc: c.dataMuted,
            shadow: c.borderDivider,
            paper: c.bgSurface,
            ink: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter({
    required this.disc,
    required this.shadow,
    required this.paper,
    required this.ink,
  });

  final Color disc;
  final Color shadow;
  final Color paper;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 170);
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = ink
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawCircle(const Offset(100, 82), 66, fill..color = disc)
      ..drawOval(
        Rect.fromCenter(center: const Offset(100, 160), width: 84, height: 10),
        fill..color = shadow,
      );
    // M58 104 a22 22 0 0 1 4-43 a32 32 0 0 1 61-8 a24 24 0 0 1 20 47 z
    final cloud = Path()
      ..moveTo(58, 104)
      ..arcToPoint(const Offset(62, 61), radius: const Radius.circular(22))
      ..arcToPoint(const Offset(123, 53), radius: const Radius.circular(32))
      ..arcToPoint(const Offset(143, 100), radius: const Radius.circular(24))
      ..close();
    canvas
      ..drawPath(cloud, fill..color = paper)
      ..drawPath(cloud, line)
      ..drawPath(
        Path()
          ..moveTo(84, 80)
          ..lineTo(96, 92)
          ..lineTo(118, 68),
        line,
      )
      ..drawCircle(const Offset(160, 34), 4, fill..color = ink)
      ..drawCircle(const Offset(40, 44), 2.5, line..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_CloudPainter old) =>
      old.disc != disc ||
      old.shadow != shadow ||
      old.paper != paper ||
      old.ink != ink;
}
