import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'tag.dart';

abstract class TagRepository {
  Future<Either<AuthFailure, List<Tag>>> list();
  Future<Either<AuthFailure, Tag>> create({
    required String clientId,
    required String name,
  });
}
