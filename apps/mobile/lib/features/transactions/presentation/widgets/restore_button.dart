import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/theme/theme_context.dart';

/// Round 40 restore button on a deleted row.
class RestoreButton extends StatelessWidget {
  const RestoreButton({
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
      child: Semantics(
        button: true,
        label: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(40, 40),
            fixedSize: const Size(40, 40),
            padding: EdgeInsets.zero,
            shape: const CircleBorder(),
            side: BorderSide(color: c.borderDefault),
            foregroundColor: c.actionPrimary,
          ),
          child: const Icon(LucideIcons.rotateCcw, size: 18),
        ),
      ),
    );
  }
}
