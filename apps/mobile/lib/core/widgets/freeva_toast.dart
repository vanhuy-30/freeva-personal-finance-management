import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Ink toast floating at the top of the screen: radius 16, at least 52 high,
/// 18 mint icon, plain blue action text. 4 s, or 6 s with an action
/// (usually "Hoàn tác"). One at a time: a new toast replaces the current one.
/// `success` shows a check when no [icon] is given.
void showFreevaToast(
  BuildContext context, {
  required String message,
  IconData? icon,
  bool success = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final c = context.colors;
  final media = MediaQuery.of(context);
  final glyph = icon ?? (success ? LucideIcons.check : null);
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: actionLabel == null
          ? FreevaMotion.toast
          : FreevaMotion.toastWithAction,
      backgroundColor: Colors.transparent,
      elevation: 0,
      // The container below paints the surface and the toast shadow.
      clipBehavior: Clip.none,
      behavior: SnackBarBehavior.floating,
      // Pinned to the top: a bottom margin of "screen height minus the toast
      // and the status bar" pushes the floating snack bar up there.
      margin: EdgeInsets.fromLTRB(
        context.screenMargin,
        0,
        context.screenMargin,
        (media.size.height - media.padding.top - 76).clamp(
          FreevaSpace.s4,
          double.infinity,
        ),
      ),
      padding: EdgeInsets.zero,
      content: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 6, 0),
        decoration: BoxDecoration(
          color: c.toastBg,
          borderRadius: BorderRadius.circular(FreevaRadius.md),
          boxShadow: FreevaElevation.toast,
        ),
        child: Row(
          children: [
            if (glyph != null) ...[
              Icon(glyph, size: FreevaSize.iconSm, color: c.toastIcon),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s2),
                child: Text(
                  message,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.toastFg,
                  ),
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 10),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction?.call();
                },
                style: TextButton.styleFrom(
                  foregroundColor: c.toastAction,
                  backgroundColor: Colors.transparent,
                  minimumSize: const Size(FreevaSize.touch, FreevaSize.touch),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
