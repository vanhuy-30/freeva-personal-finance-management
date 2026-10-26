/// Which transactions a category fits. Older servers omit it (both).
enum CategoryKind {
  expense,
  income,
  both;

  bool fits(bool income) =>
      this == both || (income ? this == CategoryKind.income : this == expense);
}

class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.parentId,
    this.clientId = '',
    this.colorToken,
    this.iconToken,
    this.isSystem = false,
    this.archived = false,
    this.version = 1,
    this.createdAt,
    this.kind = CategoryKind.both,
  });
  final String id;
  final String name;
  final String? parentId;
  final String clientId;
  final String? colorToken;
  final String? iconToken;
  final bool isSystem;
  final bool archived;
  final int version;
  final DateTime? createdAt;
  final CategoryKind kind;
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    this.parentId,
    this.colorToken,
    this.iconToken,
    this.kind = CategoryKind.both,
  });
  final String name;
  final String? parentId;
  final String? colorToken;
  final String? iconToken;

  /// Tab it is created on; the server gives a subcategory its parent's kind.
  final CategoryKind kind;
}

class CategoryOptions {
  const CategoryOptions({
    this.colorTokens = const [],
    this.iconTokens = const [],
  });
  final List<String> colorTokens;
  final List<String> iconTokens;
  bool get isReady => colorTokens.isNotEmpty && iconTokens.isNotEmpty;
}

class CategoryCatalog {
  const CategoryCatalog({required this.all, required this.recent});
  final List<FinanceCategory> all;
  final List<FinanceCategory> recent;
}

class CategoryManagement {
  const CategoryManagement({required this.items, required this.options});
  final List<FinanceCategory> items;
  final CategoryOptions options;
}
