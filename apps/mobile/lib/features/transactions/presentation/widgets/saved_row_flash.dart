import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Marks a just-saved row with `tint.blue` across the full card width that
/// fades out (C2.6). [builder] gets the mark strength (1 → 0) so the row can
/// turn its icon circle white while marked. With reduced motion the fade is
/// a short 150 ms one.
class SavedRowFlash extends StatelessWidget {
  const SavedRowFlash({
    required this.builder,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final Widget Function(double t) builder;

  /// Follows the card corners on the first / last row.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final duration = context.reduceMotion
        ? FreevaMotion.fast
        : const Duration(milliseconds: 1600);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: duration,
      curve: Curves.easeIn,
      builder: (context, t, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.tintBlue.withValues(alpha: t),
          borderRadius: borderRadius,
        ),
        child: builder(t),
      ),
    );
  }
}
