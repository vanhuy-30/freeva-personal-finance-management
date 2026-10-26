import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
    this.subtitle,
    this.accent = false,
    super.key,
  });

  SettingsRow.toggle({
    required this.icon,
    required this.title,
    required bool on,
    required ValueChanged<bool> onChanged,
    this.subtitle,
    this.accent = false,
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

  /// One short line under the title.
  final String? subtitle;

  /// Coloured icon tile (money setup) instead of the grey one (app settings).
  final bool accent;

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
                  color: destructive
                      ? c.statusDangerBg
                      : accent
                      ? c.tintBlue
                      : c.bgSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: accent && !destructive ? c.tintBlueFg : fg,
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FreevaTypography.body.copyWith(
                        color: fg,
                        fontWeight: destructive ? FontWeight.w500 : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                // Wraps (never cut) when text is large and the title is long.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * .45,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: FreevaSpace.s2),
                    child: Text(
                      value!,
                      textAlign: TextAlign.end,
                      style: FreevaTypography.body.copyWith(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ),
              if (trailing != null) trailing!,
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
