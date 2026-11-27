import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/press_scale.dart';

/// Number text of a glance tile (20/26, 600).
TextStyle glanceBig(BuildContext context) => FreevaTypography.titleL.copyWith(
  fontSize: 20,
  height: 1.3,
  letterSpacing: -0.3,
  color: context.colors.textPrimary,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Small grey line of a glance tile (12).
TextStyle glanceNote(BuildContext context) => FreevaTypography.label.copyWith(
  fontWeight: FontWeight.w400,
  height: 1.3,
  color: context.colors.textSecondary,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// One tile of the PA 3 grid: white, radius 20, tile shadow. Small tiles are
/// at least 152 tall with the header on top and the rest spread down.
class GlanceTile extends StatelessWidget {
  const GlanceTile({
    required this.semanticsLabel,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.minHeight = 152,
    super.key,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: minHeight),
            padding: padding,
            decoration: BoxDecoration(
              color: c.cardBg,
              borderRadius: BorderRadius.circular(FreevaRadius.lg),
              boxShadow: FreevaElevation.s1,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Icon box (28, radius 9) and the tile name.
class GlanceHeader extends StatelessWidget {
  const GlanceHeader({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: fg),
      ),
      const SizedBox(width: FreevaSpace.s2),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FreevaTypography.bodyS.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: context.colors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

/// Pill tag (24 tall, 12/500) used for status on tiles.
class GlanceTag extends StatelessWidget {
  const GlanceTag({
    required this.text,
    required this.bg,
    required this.fg,
    this.icon,
    super.key,
  });

  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    // 24 tall; with very large text the label wraps instead of clipping.
    constraints: const BoxConstraints(minHeight: 24),
    padding: const EdgeInsets.symmetric(
      horizontal: FreevaSpace.s2,
      vertical: FreevaSpace.s1,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(FreevaRadius.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: FreevaSpace.s1),
        ],
        Flexible(
          child: Text(
            text,
            // 16 line + 4 + 4 = 24.
            style: FreevaTypography.label.copyWith(height: 16 / 12, color: fg),
          ),
        ),
      ],
    ),
  );
}
