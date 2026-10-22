import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_button.dart';

/// Confirmation for actions that cannot be undone or lose data. The title is
/// a question, the message states the consequence, buttons name the action.
/// Returns true when confirmed.
Future<bool> showFreevaConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelLabel,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final c = context.colors;
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: context.screenMargin),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: FreevaTypography.body.copyWith(
                  fontSize: 14,
                  height: 20 / 14,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: FreevaSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: FreevaButton(
                      label: cancelLabel,
                      variant: FreevaButtonVariant.secondary,
                      size: FreevaButtonSize.s,
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
                      size: FreevaButtonSize.s,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
