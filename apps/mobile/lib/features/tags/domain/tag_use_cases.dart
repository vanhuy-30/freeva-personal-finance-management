import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/domain/auth_repository.dart';
import 'tag.dart';
import 'tag_repository.dart';

abstract class TagUseCases {
  Future<Either<AuthFailure, List<Tag>>> list();
  Future<Either<AuthFailure, Tag>> create({
    required String clientId,
    required String name,
  });
  Future<Either<AuthFailure, Tag>> rename(Tag tag, String name);
  Future<Either<AuthFailure, Unit>> delete(Tag tag);
}

@LazySingleton(as: TagUseCases)
class DefaultTagUseCases implements TagUseCases {
  DefaultTagUseCases(this._repository);
  final TagRepository _repository;

  @override
  Future<Either<AuthFailure, List<Tag>>> list() => _repository.list();

  @override
  Future<Either<AuthFailure, Tag>> create({
    required String clientId,
    required String name,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.create(clientId: clientId, name: trimmed);
  }

  @override
  Future<Either<AuthFailure, Tag>> rename(Tag tag, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 100) {
      return Future.value(left(const AuthFailure(AuthError.invalidInput)));
    }
    return _repository.rename(tag, trimmed);
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(Tag tag) => _repository.delete(tag);
}
