import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'press_scale.dart';

/// Selectable card: icon and label on one row. Selected = `tint.blue` fill,
/// 1.5 primary border and a round check. `enabled: false` dims it, for example
/// when the maximum number of choices is reached.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
    super.key,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = enabled ? c.textPrimary : c.textDisabled;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: PressScale(
        enabled: enabled,
        child: AnimatedContainer(
          duration: FreevaMotion.fast,
          constraints: const BoxConstraints(minHeight: FreevaSize.row),
          decoration: BoxDecoration(
            color: selected ? c.tintBlue : c.bgSurface,
            borderRadius: BorderRadius.circular(FreevaRadius.lg),
            border: Border.all(
              color: selected ? c.actionPrimary : c.borderDefault,
              width: selected
                  ? FreevaBorder.selected
                  : FreevaBorder.defaultValue,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(FreevaRadius.lg),
            splashFactory: NoSplash.splashFactory,
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FreevaSpace.s4,
                vertical: FreevaSpace.s3,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: FreevaSize.iconInline,
                      color: selected ? c.tintBlueFg : fg,
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.actionPrimary,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 14,
                        color: c.textOnAction,
                      ),
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
