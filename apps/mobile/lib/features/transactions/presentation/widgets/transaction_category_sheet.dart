import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../categories/domain/finance_category.dart';

Future<String?> pickCategory(
  BuildContext context,
  List<FinanceCategory> categories,
) {
  final ids = categories.map((item) => item.id).toSet();
  final children = <String?, List<FinanceCategory>>{};
  for (final category in categories) {
    final parent = category.parentId != null && ids.contains(category.parentId)
        ? category.parentId
        : null;
    (children[parent] ??= []).add(category);
  }
  final ordered = <({FinanceCategory category, int depth})>[];
  void walk(String? parent, int depth) {
    for (final category in children[parent] ?? const <FinanceCategory>[]) {
      ordered.add((category: category, depth: depth));
      walk(category.id, depth + 1);
    }
  }

  walk(null, 0);
  final s = S.of(context);
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: ListView(
        children: [
          for (final row in ordered)
            ListTile(
              contentPadding: EdgeInsets.only(
                left: 16 + row.depth * 16,
                right: 16,
              ),
              title: Text(row.category.name),
              onTap: () => Navigator.of(context).pop(row.category.id),
            ),
          if (ordered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(s.transactionCategory),
            ),
        ],
      ),
    ),
  );
}
