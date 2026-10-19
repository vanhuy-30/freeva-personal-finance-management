import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/finance_category.dart';

class CategoryDeleteChoice {
  const CategoryDeleteChoice(this.replacementId);
  final String? replacementId;
}

Future<CategoryDeleteChoice?> confirmCategoryDelete(
  BuildContext context,
  List<FinanceCategory> replacements,
) async {
  final s = S.of(context);
  String? replacementId;
  return showDialog<CategoryDeleteChoice>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(s.categoryDeleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.categoryDeleteBody),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: replacementId,
              decoration: InputDecoration(labelText: s.categoryReplacement),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(s.categoryNoReplacement),
                ),
                for (final item in replacements)
                  DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) => setState(() => replacementId = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.transactionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, CategoryDeleteChoice(replacementId)),
            child: Text(s.categoryDelete),
          ),
        ],
      ),
    ),
  );
}
