import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import '../viewmodels/category_view_model.dart';
import 'category_delete_dialog.dart';
import 'category_dialogs.dart';

Future<void> archiveCategory(
  BuildContext context,
  CategoryViewModel model,
  FinanceCategory category,
) async {
  final s = S.of(context);
  final blocked =
      !category.archived && categoryHasActiveChild(category, model.categories);
  if (blocked) {
    await showCategoryNotice(context, s.categoryHideBlocked);
    return;
  }
  if (!context.mounted) return;
  final confirmed = await confirmCategoryArchive(
    context,
    restore: category.archived,
  );
  if (confirmed) await model.archive(category);
}

Future<void> deleteCategory(
  BuildContext context,
  CategoryViewModel model,
  FinanceCategory category,
) async {
  final s = S.of(context);
  if (categoryHasChild(category, model.categories)) {
    await showCategoryNotice(context, s.categoryDeleteBlocked);
    return;
  }
  if (!context.mounted) return;
  final replacements = model.categories
      .where((item) => item.id != category.id && !item.archived)
      .toList();
  final choice = await confirmCategoryDelete(context, replacements);
  if (choice == null) return;
  await model.remove(category, replacementCategoryId: choice.replacementId);
}
