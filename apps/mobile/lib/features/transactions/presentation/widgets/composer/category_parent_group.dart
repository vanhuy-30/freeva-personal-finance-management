import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_chip.dart';
import '../../../../categories/domain/finance_category.dart';
import '../../../../categories/presentation/widgets/category_badge.dart';

/// Parent row (two-tone icon) with its children as indented chips.
class CategoryParentGroup extends StatelessWidget {
  const CategoryParentGroup({
    required this.parent,
    required this.children,
    required this.selected,
    required this.onPick,
    super.key,
  });

  final FinanceCategory parent;
  final List<FinanceCategory> children;
  final String? selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final on = parent.id == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: FreevaSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onPick(parent.id),
            child: SizedBox(
              height: FreevaSize.touch,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.tintBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon(parent.iconToken),
                      size: 18,
                      color: c.tintBlueFg,
                    ),
                  ),
                  const SizedBox(width: FreevaSpace.s3),
                  Expanded(
                    child: Text(
                      parent.name,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (on) Icon(LucideIcons.check, color: c.actionPrimary),
                ],
              ),
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kid in children)
                    FreevaChip(
                      label: kid.name,
                      selected: kid.id == selected,
                      onTap: () => onPick(kid.id),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
