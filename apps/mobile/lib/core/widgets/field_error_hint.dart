import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Error under a field: icon plus a hint that says how to fix it.
class FieldErrorHint extends StatelessWidget {
  const FieldErrorHint(this.error, {super.key});

  final String error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.circleAlert,
            size: FreevaSize.iconChip,
            color: c.statusDanger,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              error,
              style: FreevaTypography.label.copyWith(
                color: c.statusDanger,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
