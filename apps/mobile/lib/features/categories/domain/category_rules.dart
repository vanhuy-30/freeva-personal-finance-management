import 'finance_category.dart';

class CategoryRow {
  const CategoryRow(this.category, this.depth);
  final FinanceCategory category;
  final int depth;
}

bool categoryParentInvalid(
  String? parentId,
  String? selfId,
  List<FinanceCategory> categories,
) {
  if (parentId == null) return false;
  final byId = {for (final category in categories) category.id: category};
  final parent = byId[parentId];
  if (parent == null || parent.archived) return true;
  var current = parentId;
  final seen = <String>{};
  while (true) {
    if (selfId != null && current == selfId) return true;
    if (!seen.add(current)) return true;
    final next = byId[current]?.parentId;
    if (next == null) return false;
    current = next;
  }
}

/// Two levels only: a new parent must be a main category, and a category
/// with subcategories cannot get a parent.
bool categoryBreaksTwoLevels(
  String? parentId,
  FinanceCategory? self,
  List<FinanceCategory> categories,
) {
  if (parentId == null) return false;
  final parent = categories.where((c) => c.id == parentId).firstOrNull;
  return parent == null ||
      parent.parentId != null ||
      (self != null && categoryHasChild(self, categories));
}

bool categoryHasActiveChild(
  FinanceCategory category,
  List<FinanceCategory> categories,
) => categories.any((item) => item.parentId == category.id && !item.archived);

bool categoryHasChild(
  FinanceCategory category,
  List<FinanceCategory> categories,
) => categories.any((item) => item.parentId == category.id);

List<CategoryRow> orderedCategories(List<FinanceCategory> categories) {
  final ids = categories.map((item) => item.id).toSet();
  final children = <String?, List<FinanceCategory>>{};
  for (final category in categories) {
    final parent = category.parentId != null && ids.contains(category.parentId)
        ? category.parentId
        : null;
    (children[parent] ??= []).add(category);
  }
  int compare(FinanceCategory a, FinanceCategory b) {
    final created = (a.createdAt ?? DateTime.utc(0)).compareTo(
      b.createdAt ?? DateTime.utc(0),
    );
    return created != 0 ? created : a.id.compareTo(b.id);
  }

  for (final list in children.values) {
    list.sort(compare);
  }
  final ordered = <CategoryRow>[];
  void walk(String? parent, int depth) {
    for (final category in children[parent] ?? const <FinanceCategory>[]) {
      ordered.add(CategoryRow(category, depth));
      walk(category.id, depth + 1);
    }
  }

  walk(null, 0);
  return List.unmodifiable(ordered);
}

/// A main category with its subcategories, as the Danh mục list shows it.
class CategoryGroup {
  const CategoryGroup(this.parent, this.children);
  final FinanceCategory parent;
  final List<FinanceCategory> children;
}

/// Active categories of one tab (Chi or Thu), oldest first. "Both" shows in
/// either tab. A subcategory whose parent is gone or hidden is shown as a
/// main one; rows nested deeper before the two-level rule sit under their
/// top category.
List<CategoryGroup> categoryGroups(
  List<FinanceCategory> categories, {
  required bool income,
}) {
  final active = categories.where((c) => !c.archived).toList();
  final byId = {for (final c in active) c.id: c};
  String top(FinanceCategory c) {
    var current = c;
    final seen = <String>{c.id};
    while (true) {
      final parent = byId[current.parentId];
      if (parent == null || !seen.add(parent.id)) return current.id;
      current = parent;
    }
  }

  final roots = <String, FinanceCategory>{};
  final children = <String, List<FinanceCategory>>{};
  for (final row in orderedCategories(active)) {
    final c = row.category;
    final root = top(c);
    if (root == c.id) {
      roots[c.id] = c;
    } else {
      (children[root] ??= []).add(c);
    }
  }
  return [
    for (final parent in roots.values)
      if (parent.kind.fits(income))
        CategoryGroup(parent, List.unmodifiable(children[parent.id] ?? [])),
  ];
}

/// Hidden categories as the "Danh mục đã ẩn" list shows them: a hidden
/// category whose parent is visible (or gone), with its hidden subcategories.
List<CategoryGroup> hiddenCategoryGroups(List<FinanceCategory> categories) {
  final hidden = {
    for (final c in categories)
      if (c.archived) c.id: c,
  };
  return [
    for (final row in orderedCategories(hidden.values.toList()))
      if (row.depth == 0)
        CategoryGroup(
          row.category,
          List.unmodifiable([
            for (final c in hidden.values)
              if (c.parentId == row.category.id) c,
          ]),
        ),
  ];
}
