import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// An active condition: ink chip, white text, × removes only this one.
class ActiveFilterChip extends StatelessWidget {
  const ActiveFilterChip({
    required this.label,
    required this.onRemove,
    this.semanticsLabel,
    super.key,
  });

  final String label;
  final VoidCallback onRemove;

  /// Spoken label; defaults to "Bỏ {label}".
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: semanticsLabel ?? S.of(context).txChipRemove(label),
        excludeSemantics: true,
        child: Material(
          color: c.chipFilterSelectedBg,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onRemove,
            child: Container(
              height: 36,
              padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w600,
                      color: c.chipFilterSelectedFg,
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s1),
                  Icon(
                    LucideIcons.x,
                    size: FreevaSize.iconChip,
                    color: c.chipFilterSelectedFg,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
