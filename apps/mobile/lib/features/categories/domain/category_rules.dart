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
