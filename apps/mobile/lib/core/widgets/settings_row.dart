import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'freeva_switch.dart';

/// Settings row, 56 high, 32 icon tile, 12 between parts. Trailing is one of:
/// a [FreevaSwitch]
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
    this.tint,
    this.minHeight = FreevaSize.row,
    super.key,
  });

  SettingsRow.toggle({
    required this.icon,
    required this.title,
    required bool on,
    required ValueChanged<bool> onChanged,
    this.subtitle,
    this.accent = false,
    this.tint,
    this.minHeight = FreevaSize.row,
    super.key,
  }) : value = null,
       chevron = false,
       destructive = false,
       onTap = (() => onChanged(!on)),
       trailing = FreevaSwitch(value: on, onChanged: onChanged);

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

  /// Tile colours (background, glyph), e.g. `(c.statusWarningBg,
  /// c.statusWarning)`. Overrides [accent]; ignored for [destructive] rows.
  final (Color, Color)? tint;

  /// Row minimum height: 56, or 54 / 60 on some boards.
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = destructive ? c.statusDanger : c.textPrimary;
    final (tileBg, tileFg) = destructive
        ? (c.statusDangerBg, fg)
        : tint ?? (accent ? (c.tintBlue, c.tintBlueFg) : (c.bgSubtle, fg));
    const gap = SizedBox(width: FreevaSpace.s3);
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.bgSubtle,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
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
                  color: tileBg,
                  borderRadius: BorderRadius.circular(FreevaRadius.xs),
                ),
                child: Icon(icon, size: FreevaSize.iconSm, color: tileFg),
              ),
              gap,
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
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
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
                    padding: const EdgeInsetsDirectional.only(
                      start: FreevaSpace.s3,
                    ),
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
              if (trailing != null) ...[gap, trailing!],
              if (chevron && trailing == null && !destructive) ...[
                gap,
                Icon(
                  LucideIcons.chevronRight,
                  size: FreevaSize.iconChip,
                  color: c.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
