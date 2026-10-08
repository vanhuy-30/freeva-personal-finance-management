import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'finance_category.dart';

abstract class CategoryRepository {
  Future<Either<AuthFailure, CategoryCatalog>> load();
}
