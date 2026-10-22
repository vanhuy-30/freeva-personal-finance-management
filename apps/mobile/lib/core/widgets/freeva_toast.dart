import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Ink toast floating above the bottom nav. 4 s, or 6 s with an action
/// (usually "Hoàn tác"). One at a time: a new toast replaces the current one.
void showFreevaToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  bool aboveNav = true,
}) {
  final c = context.colors;
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: actionLabel == null
          ? FreevaMotion.toast
          : FreevaMotion.toastWithAction,
      backgroundColor: c.toastBg,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      margin: EdgeInsets.fromLTRB(
        context.screenMargin,
        0,
        context.screenMargin,
        aboveNav ? FreevaLayout.navReserve : FreevaSpace.s4,
      ),
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: FreevaSize.iconInline, color: c.toastFg),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: FreevaTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c.toastFg,
                ),
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: c.toastFg,
                  backgroundColor: c.toastFg.withValues(alpha: .12),
                  minimumSize: const Size(FreevaSize.touch, 36),
                  textStyle: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(actionLabel),
              ),
          ],
        ),
      ),
    ),
  );
}
