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
}

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    this.parentId,
    this.colorToken,
    this.iconToken,
  });
  final String name;
  final String? parentId;
  final String? colorToken;
  final String? iconToken;
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
