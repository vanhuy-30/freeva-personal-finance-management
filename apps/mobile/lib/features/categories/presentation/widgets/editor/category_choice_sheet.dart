import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../../../../core/widgets/freeva_sheet.dart';
import '../../../domain/finance_category.dart';
import '../category_icon_tile.dart';

/// One-pick category sheet: "Thuộc danh mục chính" (E, màn 3) or the target
/// of moved transactions in the delete popup. Icon + radio per row.
Future<String?> showCategoryChoiceSheet(
  BuildContext context, {
  required String title,
  required List<FinanceCategory> choices,
  required String? selected,
}) => showFreevaSheet<String>(
  context: context,
  title: title,
  builder: (context) {
    final c = context.colors;
    return SingleChildScrollView(
      child: FreevaCard(
        list: true,
        padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
        child: Column(
          children: [
            for (final (i, category) in choices.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.listDivider),
              _ChoiceRow(
                category: category,
                selected: category.id == selected,
                onTap: () => Navigator.of(context).pop(category.id),
              ),
            ],
          ],
        ),
      ),
    );
  },
);

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FinanceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: FreevaSize.row,
          child: Row(
            children: [
              CategoryIconTile(
                iconToken: category.iconToken,
                colorToken: category.colorToken,
                size: 36,
              ),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.actionPrimary : null,
                  border: selected
                      ? null
                      : Border.all(color: c.borderDefault, width: 1.5),
                ),
                child: selected
                    ? Icon(LucideIcons.check, size: 14, color: c.textOnAction)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
