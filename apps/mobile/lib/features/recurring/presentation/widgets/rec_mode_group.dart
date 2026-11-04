import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';

/// Two-line radio group "Ghi tự động" / "Hỏi trước khi ghi": 64 high rows,
/// 32 icon tile, title + hint, round radio at the end. [remindEnabled]
/// false greys the second row (only an expense can ask first).
class RecModeGroup extends StatelessWidget {
  const RecModeGroup({
    required this.remind,
    required this.onChanged,
    this.remindEnabled = true,
    super.key,
  });

  final bool remind;
  final ValueChanged<bool>? onChanged;
  final bool remindEnabled;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Semantics(
      container: true,
      child: FreevaCard(
        list: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _Option(
              icon: LucideIcons.repeat,
              background: c.statusWarningBg,
              foreground: c.statusWarning,
              title: s.recModeAuto,
              hint: s.recModeAutoSub,
              selected: !remind,
              onTap: onChanged == null ? null : () => onChanged!(false),
            ),
            Divider(height: 1, thickness: 1, color: c.listDivider),
            _Option(
              icon: LucideIcons.bell,
              background: c.tintBlue,
              foreground: c.tintBlueFg,
              title: s.recModeRemind,
              hint: s.recModeRemindSub,
              selected: remind,
              enabled: remindEnabled,
              onTap: onChanged == null || !remindEnabled
                  ? null
                  : () => onChanged!(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String title;
  final String hint;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      container: true,
      excludeSemantics: true,
      label: '$title, $hint',
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(FreevaRadius.xs),
                    ),
                    child: Icon(icon, size: 16, color: foreground),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: FreevaTypography.body.copyWith(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hint,
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w400,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c.actionPrimary : c.inputBorder,
                        width: selected ? 6 : 1.5,
                      ),
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
