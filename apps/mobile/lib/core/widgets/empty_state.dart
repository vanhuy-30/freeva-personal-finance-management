import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'f_strokes_mark.dart';
import 'freeva_button_style.dart';
import 'press_scale.dart';

/// Empty state: the static F illustration (or, with [animated], the drifting
/// F-strokes tile), a short title, one line, and an optional secondary
/// action. Gaps 20 / 8 / 20, as on TxNoResult and RepEmpty.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.animated = false,
    super.key,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Uses the old 64 animated F-strokes tile instead of the illustration.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FreevaSpace.s5,
        vertical: FreevaSpace.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (animated) const FStrokesMark() else const FStrokesIllustration(),
          const SizedBox(height: FreevaSpace.s5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: FreevaSpace.s2),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: FreevaSpace.s5),
            // Secondary, 44 high, padding 20, 15/600.
            PressScale(
              enabled: onAction != null,
              child: TextButton(
                onPressed: onAction,
                style:
                    freevaButtonStyle(
                      c,
                      FreevaButtonVariant.secondary,
                      FreevaButtonSize.s,
                    ).copyWith(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: FreevaSpace.s5),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        FreevaTypography.titleM,
                      ),
                    ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
