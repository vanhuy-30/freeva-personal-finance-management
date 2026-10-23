import 'package:flutter/foundation.dart';

import '../../domain/category_rules.dart';
import '../../domain/finance_category.dart';

enum CategoryFormError { name, parent }

/// State of the add / edit category form (E, màn 2 and 5). The name stays in
/// the page's text field until [build].
class CategoryForm extends ChangeNotifier {
  CategoryForm({
    required this.categories,
    required this.clientId,
    required CategoryKind tabKind,
    this.category,
  }) : kind = category?.kind ?? tabKind,
       child = category?.parentId != null,
       parentId = category?.parentId,
       colorToken = category?.colorToken,
       iconToken = category?.iconToken;

  final List<FinanceCategory> categories;

  /// Kept for the whole form, so a retried create is not duplicated.
  final String clientId;

  /// Null when adding.
  final FinanceCategory? category;

  /// Tab it is added on; a subcategory takes its parent's kind on the server.
  final CategoryKind kind;
  bool child;
  String? parentId;
  String? colorToken;
  String? iconToken;
  Set<CategoryFormError> errors = const {};

  bool get isNew => category == null;

  /// A main category with subcategories stays a main category.
  bool get canBeChild =>
      category == null || !categoryHasChild(category!, categories);

  /// Active main categories of this tab ("both" fits either), not itself.
  List<FinanceCategory> get parentChoices => [
    for (final c in categories)
      if (!c.archived &&
          c.parentId == null &&
          c.id != category?.id &&
          (kind == CategoryKind.both ||
              c.kind == CategoryKind.both ||
              c.kind == kind))
        c,
  ];

  FinanceCategory? get parent =>
      categories.where((c) => c.id == parentId).firstOrNull;

  void setChild(bool value) {
    if (child == value || (value && !canBeChild)) return;
    child = value;
    errors = errors.difference({CategoryFormError.parent});
    notifyListeners();
  }

  void setParent(String id) {
    parentId = id;
    child = true;
    errors = errors.difference({CategoryFormError.parent});
    notifyListeners();
  }

  void setColor(String? value) {
    colorToken = value;
    notifyListeners();
  }

  void setIcon(String? value) {
    iconToken = value;
    notifyListeners();
  }

  /// The draft to save, or null after marking what is missing in [errors].
  CategoryDraft? build(String name) {
    final parent = child ? parentId : null;
    errors = {
      if (name.trim().isEmpty) CategoryFormError.name,
      if (child && parent == null) CategoryFormError.parent,
    };
    notifyListeners();
    if (errors.isNotEmpty) return null;
    return CategoryDraft(
      name: name.trim(),
      parentId: parent,
      colorToken: colorToken,
      iconToken: iconToken,
      kind: kind,
    );
  }
}
