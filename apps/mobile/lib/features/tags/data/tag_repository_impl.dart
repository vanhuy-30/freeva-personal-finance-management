import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/tag.dart';
import '../domain/tag_repository.dart';

@LazySingleton(as: TagRepository)
class TagRepositoryImpl implements TagRepository {
  TagRepositoryImpl(this._api);
  final AuthorizedApi _api;

  Tag _parse(Map<String, dynamic> json) => Tag(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    name: json['name'] as String,
    version: json['version'] as int,
  );

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _api.request(method, path, body: body);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, List<Tag>>> list() async {
    final items = <Tag>[];
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'tags?pageSize=100&page=$page',
        (json) => json,
      );
      final error = result.fold<AuthFailure?>((e) => e, (_) => null);
      if (error != null) return left(error);
      try {
        final json = result.getOrElse(() => throw const FormatException());
        final rows = (json['items'] as List)
            .map((item) => _parse(item as Map<String, dynamic>))
            .toList();
        items.addAll(rows);
        if (items.length >= (json['total'] as int)) {
          return right(List.unmodifiable(items));
        }
        if (rows.isEmpty) throw const FormatException();
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    }
  }

  @override
  Future<Either<AuthFailure, Tag>> create({
    required String clientId,
    required String name,
  }) => _request(
    'POST',
    'tags',
    _parse,
    body: {'clientId': clientId, 'name': name},
  );
}
