import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import 'category_icon_tile.dart';

/// A main category and, when open, its subcategories. Tapping the name or
/// icon edits; only the round button opens or closes.
class CategoryGroupRows extends StatelessWidget {
  const CategoryGroupRows({
    required this.group,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
    super.key,
  });

  final CategoryGroup group;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<FinanceCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final parent = group.parent;
    final count = group.children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                button: true,
                label: [
                  parent.name,
                  if (count > 0) s.categoryChildCount(count),
                ].join(', '),
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => onOpen(parent),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 60),
                    child: Row(
                      children: [
                        CategoryIconTile(
                          iconToken: parent.iconToken,
                          colorToken: parent.colorToken,
                        ),
                        const SizedBox(width: FreevaSpace.s3),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parent.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FreevaTypography.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: c.textPrimary,
                                ),
                              ),
                              if (count > 0)
                                Text(
                                  s.categoryChildCount(count),
                                  style: FreevaTypography.label.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: c.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: FreevaSpace.s3),
            if (count > 0)
              _ToggleButton(
                expanded: expanded,
                label: s.categoryToggleSemantics(parent.name),
                onTap: onToggle,
              )
            else
              SizedBox(
                width: 36,
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: c.textDisabled,
                ),
              ),
          ],
        ),
        if (expanded)
          for (final child in group.children)
            Semantics(
              container: true,
              button: true,
              label: child.name,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onOpen(child),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: FreevaSize.touch,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Row(
                      children: [
                        CategoryDot(
                          colorToken: child.colorToken ?? parent.colorToken,
                        ),
                        const SizedBox(width: FreevaSpace.s3),
                        Expanded(
                          child: Text(
                            child.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FreevaTypography.body.copyWith(
                              fontSize: 14,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

/// Round 36 button; open = `tint.blue` with the arrow up.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.expanded,
    required this.label,
    required this.onTap,
  });

  final bool expanded;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      button: true,
      expanded: expanded,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: FreevaSize.touch,
        child: Center(
          child: Material(
            color: expanded ? c.tintBlue : c.bgSubtle,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 36,
                child: Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: expanded ? c.actionPrimary : c.textOnWash,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
