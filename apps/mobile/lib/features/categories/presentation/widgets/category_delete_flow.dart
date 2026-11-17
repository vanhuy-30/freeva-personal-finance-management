import 'package:flutter/material.dart';

import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'editor/category_delete_popup.dart';

/// Asks how to handle the transactions of [category] (move them to another
/// category), then deletes it. Shared by the editor's "Xoá" and the list's
/// swipe action. True when it was deleted.
Future<bool> confirmAndDeleteCategory(
  BuildContext context,
  CategoryViewModel model,
  FinanceCategory category,
) async {
  final count = await model.usage(category);
  if (count == null || !context.mounted) return false;
  final targets = [
    for (final group in categoryGroups(
      model.categories,
      income: category.kind == CategoryKind.income,
    )) ...[group.parent, ...group.children],
  ].where((c) => c.id != category.id).toList();
  final choice = await showCategoryDeletePopup(
    context,
    category: category,
    transactionCount: count,
    targets: targets,
    initialTarget: category.parentId ?? targets.firstOrNull?.id,
  );
  if (choice == null) return false;
  return model.remove(category, replacementCategoryId: choice.replacementId);
}
