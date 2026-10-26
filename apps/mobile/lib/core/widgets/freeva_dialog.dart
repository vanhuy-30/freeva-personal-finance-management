import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_button.dart';

/// Colour of the icon tile above a dialog title.
enum FreevaDialogTone {
  /// Red tile (delete, discard, log out).
  danger,

  /// Blue tile.
  info,
}

/// Dialog surface: white, radius 28, dialog shadow, padding 24/18/18/18,
/// 20 from the screen edges. Wrap custom dialog content in it.
class FreevaDialog extends StatelessWidget {
  const FreevaDialog({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.screenMargin,
        vertical: FreevaSpace.s6,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(FreevaRadius.sheet),
          boxShadow: FreevaElevation.dialog,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
          child: child,
        ),
      ),
    );
  }
}

/// 48 tile (radius 16) with a 22 glyph, above a dialog title.
class FreevaDialogIcon extends StatelessWidget {
  const FreevaDialogIcon({
    required this.icon,
    this.tone = FreevaDialogTone.danger,
    super.key,
  });

  final IconData icon;
  final FreevaDialogTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      FreevaDialogTone.danger => (c.statusDangerBg, c.statusDanger),
      FreevaDialogTone.info => (c.tintBlue, c.tintBlueFg),
    };
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(FreevaRadius.md),
        ),
        child: Icon(icon, size: 22, color: fg),
      ),
    );
  }
}

/// Confirmation for actions that cannot be undone or lose data. The title is
/// a question, the message states the consequence, buttons name the action.
/// Optional [icon] sits in a 48 tile above the title. Returns true when
/// confirmed.
Future<bool> showFreevaConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool destructive = false,
  IconData? icon,
  FreevaDialogTone iconTone = FreevaDialogTone.danger,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      return FreevaDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: FreevaDialogIcon(icon: icon, tone: iconTone),
              ),
              const SizedBox(height: 10),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: FreevaSpace.s4),
            Row(
              children: [
                Expanded(
                  child: FreevaButton(
                    label: cancelLabel,
                    variant: FreevaButtonVariant.secondary,
                    size: FreevaButtonSize.dialog,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s2),
                Expanded(
                  child: FreevaButton(
                    label: confirmLabel,
                    variant: destructive
                        ? FreevaButtonVariant.destructive
                        : FreevaButtonVariant.ink,
                    size: FreevaButtonSize.dialog,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return result ?? false;
}
