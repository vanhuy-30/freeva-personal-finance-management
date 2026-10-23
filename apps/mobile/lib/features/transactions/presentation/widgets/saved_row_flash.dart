import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Marks a just-saved row with `tint.blue` that fades out (C2.6). With
/// reduced motion the fade is a short 150 ms one.
class SavedRowFlash extends StatelessWidget {
  const SavedRowFlash({required this.child, super.key});

  final Widget child;

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
      builder: (context, t, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.tintBlue.withValues(alpha: t),
          borderRadius: BorderRadius.circular(FreevaRadius.sm),
        ),
        child: child,
      ),
      child: child,
    );
  }
}
