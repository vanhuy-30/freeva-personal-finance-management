import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// Editable tag chips (violet, 36 high, ×) and "+ Thêm nhãn".
class TagEditChips extends StatelessWidget {
  const TagEditChips({
    required this.names,
    required this.ids,
    required this.onRemove,
    required this.onAdd,
    super.key,
  });

  final Map<String, String> names;
  final List<String> ids;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Board `.tag`: 36 high, padding 0 6 0 12, 14/500, × in a 28 box.
        for (final id in ids)
          Semantics(
            button: true,
            label: s.txChipRemove(names[id] ?? ''),
            excludeSemantics: true,
            child: Material(
              color: c.tintViolet,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => onRemove(id),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        names[id] ?? '',
                        style: FreevaTypography.bodyM.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.tintVioletFg,
                        ),
                      ),
                      const SizedBox(width: 2),
                      SizedBox.square(
                        dimension: 28,
                        child: Icon(
                          LucideIcons.x,
                          size: FreevaSize.iconXs,
                          color: c.tintVioletFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // "+ Thêm nhãn": dashed ink-300 outline, 14/500 text.on-wash.
        Semantics(
          button: true,
          label: s.txAddTag,
          excludeSemantics: true,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onAdd,
            child: CustomPaint(
              painter: _DashedPill(c.borderStrong),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: FreevaSize.iconXs,
                      color: c.textOnWash,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.txAddTag,
                      style: FreevaTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textOnWash,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 1 px dashed stadium outline (3 on, 3 off like CSS `dashed`).
class _DashedPill extends CustomPainter {
  const _DashedPill(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.5),
      Radius.circular(size.height / 2),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (double d = 0; d < metric.length; d += 6) {
        canvas.drawPath(metric.extractPath(d, d + 3), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPill old) => old.color != color;
}
