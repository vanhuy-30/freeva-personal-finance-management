import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'category_actions.dart';
import 'category_badge.dart';
import 'category_editor.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.model,
    required this.row,
    required this.enabled,
    super.key,
  });
  final CategoryViewModel model;
  final CategoryRow row;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final category = row.category;
    return Card(
      key: ValueKey(category.id),
      margin: EdgeInsets.fromLTRB(16 + row.depth * 16, 6, 16, 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryBadge(
                  colorToken: category.colorToken,
                  iconToken: category.iconToken,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (category.isSystem) Text(s.categorySystem),
            Wrap(
              children: [
                TextButton(
                  onPressed: enabled ? () => _edit(context, category) : null,
                  child: Text(s.categoryEdit),
                ),
                TextButton(
                  onPressed: enabled
                      ? () => archiveCategory(context, model, category)
                      : null,
                  child: Text(
                    category.archived ? s.categoryRestore : s.categoryHide,
                  ),
                ),
                TextButton(
                  onPressed: enabled
                      ? () => deleteCategory(context, model, category)
                      : null,
                  child: Text(s.categoryDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, FinanceCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CategoryEditor(model: model, category: category),
      ),
    );
  }
}
