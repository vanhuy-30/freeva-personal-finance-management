import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/category_rules.dart';
import '../viewmodels/category_view_model.dart';
import 'category_tile.dart';

class CategoryList extends StatelessWidget {
  const CategoryList({required this.model, required this.archived, super.key});
  final CategoryViewModel model;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = orderedCategories(
      model.categories.where((item) => item.archived == archived).toList(),
    );
    final enabled = !model.busy && !model.needsReload;
    if (items.isEmpty && !model.busy && model.failure == null) {
      return Center(
        child: Text(archived ? s.categoryHiddenEmpty : s.categoryEmpty),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) =>
          CategoryTile(model: model, row: items[index], enabled: enabled),
    );
  }
}
