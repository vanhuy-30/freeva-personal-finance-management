import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_sheet.dart';

/// One line of [showImportPickSheet].
class ImportPickOption<T> {
  const ImportPickOption(this.value, this.label);
  final T? value;
  final String label;
}

/// Single choice sheet. Returns a record so "no choice" (null value, for a
/// column the user does not use) differs from dismissing (null result).
Future<({T? value})?> showImportPickSheet<T>(
  BuildContext context, {
  required String title,
  required List<ImportPickOption<T>> options,
  T? selected,
}) => showFreevaSheet<({T? value})>(
  context: context,
  title: title,
  builder: (sheet) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in options)
              _PickRow(
                label: option.label,
                selected: option.value == selected,
                onTap: () => Navigator.of(sheet).pop((value: option.value)),
              ),
          ],
        ),
      ),
    ],
  ),
);

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      container: true,
      excludeSemantics: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FreevaSize.row),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  LucideIcons.check,
                  size: FreevaSize.iconInline,
                  color: c.actionPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Value chip of a row: 36 high, radius 12, `bg.subtle`, 14/500 with a
/// 14 chevron. [muted] is the "Không dùng" / "Chọn" look.
class ImportPill extends StatelessWidget {
  const ImportPill({
    required this.label,
    required this.onTap,
    this.muted = false,
    this.dashed = false,
    this.leading,
    super.key,
  });
  final String label;
  final VoidCallback onTap;
  final bool muted;

  /// Dashed warning outline for a name that is not matched yet.
  final bool dashed;

  /// Small icon tile of the chosen wallet or category.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = muted ? c.textSecondary : c.textPrimary;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FreevaTypography.bodyM.copyWith(
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
                  color: dashed ? c.statusWarning : color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: dashed ? c.statusWarning : c.textSecondary,
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FreevaRadius.sm),
        child: dashed
            ? CustomPaint(
                painter: _DashedBorder(c.statusWarning),
                child: content,
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: c.bgSubtle,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: content,
              ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(FreevaRadius.sm),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += 8) {
        canvas.drawPath(metric.extractPath(at, at + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
