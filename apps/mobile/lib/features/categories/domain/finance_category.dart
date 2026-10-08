class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.parentId,
  });
  final String id;
  final String name;
  final String? parentId;
}

class CategoryCatalog {
  const CategoryCatalog({required this.all, required this.recent});
  final List<FinanceCategory> all;
  final List<FinanceCategory> recent;
}
