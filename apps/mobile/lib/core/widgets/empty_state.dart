import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'f_strokes_mark.dart';
import 'freeva_button.dart';

/// Empty state: drifting F strokes (3 s loop, still when motion is reduced),
/// a short title, one line, and an optional small primary action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          const FStrokesMark(),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: FreevaSpace.s1),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: FreevaSpace.s3),
            FreevaButton(
              label: actionLabel!,
              onPressed: onAction,
              size: FreevaButtonSize.s,
            ),
          ],
        ],
      ),
    );
  }
}
