import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// Round icon button with a red outline: delete in the detail sheet.
class DeleteCircleButton extends StatelessWidget {
  const DeleteCircleButton({
    required this.label,
    required this.onPressed,
    super.key,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(FreevaSize.button, FreevaSize.button),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: BorderSide(color: c.statusDanger),
          foregroundColor: c.statusDanger,
        ),
        child: Semantics(
          label: label,
          child: const Icon(LucideIcons.trash2, size: FreevaSize.iconInline),
        ),
      ),
    );
  }
}
