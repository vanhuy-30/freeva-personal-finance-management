import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';

/// Read-only box with a lock icon. The reason is spoken through
/// [semanticsLabel]; on screen only the lock shows it.
class LockedField extends StatelessWidget {
  const LockedField({
    required this.label,
    required this.value,
    required this.semanticsLabel,
    super.key,
  });

  final String label;
  final String value;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(
          horizontal: FreevaSpace.s4,
          vertical: FreevaSpace.s2,
        ),
        decoration: BoxDecoration(
          color: c.bgSubtle,
          borderRadius: BorderRadius.circular(FreevaComponent.inputRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: FreevaTypography.label.copyWith(
                      fontWeight: FontWeight.w400,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: FreevaTypography.body.copyWith(
                      fontSize: 16,
                      color: c.textOnWash,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.lock, size: 18, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
