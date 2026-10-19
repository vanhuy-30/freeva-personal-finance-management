import 'package:flutter/material.dart';

import 'category_badge.dart';

class CategoryTokenMenu extends StatelessWidget {
  const CategoryTokenMenu({
    required this.label,
    required this.emptyLabel,
    required this.value,
    required this.tokens,
    required this.onChanged,
    required this.leading,
    super.key,
  });
  final String label;
  final String emptyLabel;
  final String? value;
  final List<String> tokens;
  final ValueChanged<String?> onChanged;
  final Widget Function(String token) leading;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String?>(
    isExpanded: true,
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      DropdownMenuItem(value: null, child: Text(emptyLabel)),
      for (final token in tokens)
        DropdownMenuItem(
          value: token,
          child: Row(
            children: [
              leading(token),
              const SizedBox(width: 8),
              Expanded(child: Text(token, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
    ],
    onChanged: onChanged,
  );
}

Widget categoryColorLeading(String token) => CategoryBadge(colorToken: token);

Widget categoryIconLeading(String token) => Icon(categoryIcon(token));
