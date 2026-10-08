import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'category_repository.dart';
import 'category_rules.dart';
import 'finance_category.dart';

abstract class CategoryUseCases {
  Future<Either<AuthFailure, CategoryCatalog>> load();
  Future<Either<AuthFailure, CategoryManagement>> manage();
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft,
    List<FinanceCategory> categories,
    CategoryOptions options, {
    FinanceCategory? category,
    required String clientId,
  });
  Future<Either<AuthFailure, FinanceCategory>> update(
    FinanceCategory category,
    List<FinanceCategory> categories, {
    required bool archived,
  });
  Future<Either<AuthFailure, void>> delete(
    FinanceCategory category,
    List<FinanceCategory> categories, {
    String? replacementCategoryId,
  });
}

@LazySingleton(as: CategoryUseCases)
class DefaultCategoryUseCases implements CategoryUseCases {
  DefaultCategoryUseCases(this._repository);
  final CategoryRepository _repository;
  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() => _repository.load();
  @override
  Future<Either<AuthFailure, CategoryManagement>> manage() =>
      _repository.manage();

  bool _token(String? value, List<String> allowed) =>
      value == null ||
      (value.isNotEmpty && value.length <= 100 && allowed.contains(value));

  bool _stale(FinanceCategory category) =>
      category.version < 1 || category.version >= 2147483647;

  @override
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft,
    List<FinanceCategory> categories,
    CategoryOptions options, {
    FinanceCategory? category,
    required String clientId,
  }) {
    final name = draft.name.trim();
    if (name.isEmpty ||
        name.length > 100 ||
        categoryParentInvalid(draft.parentId, category?.id, categories) ||
        !_token(draft.colorToken, options.colorTokens) ||
        !_token(draft.iconToken, options.iconTokens)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (category != null && _stale(category)) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.save(draft, category: category, clientId: clientId);
  }

  @override
  Future<Either<AuthFailure, FinanceCategory>> update(
    FinanceCategory category,
    List<FinanceCategory> categories, {
    required bool archived,
  }) {
    if (!category.archived &&
        archived &&
        categoryHasActiveChild(category, categories)) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (_stale(category)) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.update(category, archived: archived);
  }

  @override
  Future<Either<AuthFailure, void>> delete(
    FinanceCategory category,
    List<FinanceCategory> categories, {
    String? replacementCategoryId,
  }) {
    final replacement = categories
        .where((item) => item.id == replacementCategoryId)
        .firstOrNull;
    if (categoryHasChild(category, categories) ||
        (replacementCategoryId != null &&
            (replacement == null ||
                replacement.archived ||
                replacement.id == category.id))) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    if (_stale(category)) {
      return Future.value(left(const AuthFailure(AuthError.conflict)));
    }
    return _repository.delete(
      category,
      replacementCategoryId: replacementCategoryId,
    );
  }
}
