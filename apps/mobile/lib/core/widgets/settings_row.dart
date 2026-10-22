import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Settings row, 56 high, 32 icon tile. Trailing is one of: a switch
/// ([SettingsRow.toggle]), a value + chevron, a chevron, or nothing.
/// `destructive` rows go last and use the error colour.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.chevron = true,
    this.destructive = false,
    this.trailing,
    super.key,
  });

  SettingsRow.toggle({
    required this.icon,
    required this.title,
    required bool on,
    required ValueChanged<bool> onChanged,
    super.key,
  }) : value = null,
       chevron = false,
       destructive = false,
       onTap = (() => onChanged(!on)),
       trailing = Switch(value: on, onChanged: onChanged);

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool chevron;
  final bool destructive;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.statusDanger : c.textPrimary;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.bgSubtle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FreevaSize.row),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FreevaSpace.s4,
            vertical: FreevaSpace.s2,
          ),
          child: Row(
            children: [
              Container(
                width: FreevaSize.iconTile,
                height: FreevaSize.iconTile,
                decoration: BoxDecoration(
                  color: destructive ? c.statusDangerBg : c.bgSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: fg),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  title,
                  style: FreevaTypography.body.copyWith(
                    color: fg,
                    fontWeight: destructive ? FontWeight.w500 : null,
                  ),
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: FreevaSpace.s2),
                  child: Text(
                    value!,
                    maxLines: 1,
                    style: FreevaTypography.body.copyWith(
                      fontSize: 14,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ?trailing,
              if (chevron && trailing == null && !destructive)
                Icon(
                  LucideIcons.chevronRight,
                  size: FreevaSize.iconInline,
                  color: c.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
