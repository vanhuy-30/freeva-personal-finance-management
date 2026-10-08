import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'category_repository.dart';
import 'finance_category.dart';

abstract class CategoryUseCases {
  Future<Either<AuthFailure, CategoryCatalog>> load();
}

@LazySingleton(as: CategoryUseCases)
class DefaultCategoryUseCases implements CategoryUseCases {
  DefaultCategoryUseCases(this._repository);
  final CategoryRepository _repository;
  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() => _repository.load();
}
