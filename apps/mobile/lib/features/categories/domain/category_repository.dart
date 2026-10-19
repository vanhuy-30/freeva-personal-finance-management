import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'finance_category.dart';

abstract class CategoryRepository {
  Future<Either<AuthFailure, CategoryCatalog>> load();
  Future<Either<AuthFailure, CategoryManagement>> manage();
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft, {
    FinanceCategory? category,
    required String clientId,
  });
  Future<Either<AuthFailure, FinanceCategory>> update(
    FinanceCategory category, {
    required bool archived,
  });
  Future<Either<AuthFailure, void>> delete(
    FinanceCategory category, {
    String? replacementCategoryId,
  });
}
