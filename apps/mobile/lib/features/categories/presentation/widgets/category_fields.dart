import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';
import 'category_token_menu.dart';

class CategoryFields extends StatelessWidget {
  const CategoryFields({
    required this.name,
    required this.parentId,
    required this.colorToken,
    required this.iconToken,
    required this.categories,
    required this.options,
    required this.onParent,
    required this.onColor,
    required this.onIcon,
    this.selfId,
    super.key,
  });
  final TextEditingController name;
  final String? parentId;
  final String? colorToken;
  final String? iconToken;
  final String? selfId;
  final List<FinanceCategory> categories;
  final CategoryOptions options;
  final ValueChanged<String?> onParent;
  final ValueChanged<String?> onColor;
  final ValueChanged<String?> onIcon;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final parents = categories.where((item) {
      if (selfId != null && item.id == selfId) return false;
      if (item.id == parentId) return true;
      return !categoryParentInvalid(item.id, selfId, categories);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: name,
          maxLength: 100,
          decoration: InputDecoration(labelText: s.categoryName),
        ),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          initialValue: parentId,
          decoration: InputDecoration(labelText: s.categoryParent),
          items: [
            DropdownMenuItem(value: null, child: Text(s.categoryNoParent)),
            for (final item in parents)
              DropdownMenuItem(
                value: item.id,
                child: Text(item.name, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: onParent,
        ),
        CategoryTokenMenu(
          label: s.categoryColor,
          emptyLabel: s.categoryNoColor,
          value: colorToken,
          tokens: options.colorTokens,
          onChanged: onColor,
          leading: categoryColorLeading,
        ),
        CategoryTokenMenu(
          label: s.categoryIcon,
          emptyLabel: s.categoryNoIcon,
          value: iconToken,
          tokens: options.iconTokens,
          onChanged: onIcon,
          leading: categoryIconLeading,
        ),
      ],
    );
  }
}
