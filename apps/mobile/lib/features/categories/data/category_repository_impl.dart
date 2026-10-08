import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/category_repository.dart';
import '../domain/finance_category.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._api);
  final AuthorizedApi _api;

  FinanceCategory _parse(Map<String, dynamic> json) => FinanceCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    parentId: json['parentId'] as String?,
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
  Future<Either<AuthFailure, CategoryCatalog>> load() async {
    final seeded = await _api.request('POST', 'categories/defaults');
    final seedError = seeded.fold<AuthFailure?>((error) => error, (_) => null);
    if (seedError != null) return left(seedError);
    final recent = await _request(
      'GET',
      'categories/recent',
      (json) => (json['items'] as List)
          .map((item) => _parse(item as Map<String, dynamic>))
          .toList(),
    );
    final recentError = recent.fold<AuthFailure?>(
      (error) => error,
      (_) => null,
    );
    if (recentError != null) return left(recentError);
    final items = <FinanceCategory>[];
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'categories?status=active&pageSize=100&page=$page',
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
          return right(
            CategoryCatalog(
              all: List.unmodifiable(items),
              recent: List.unmodifiable(recent.getOrElse(() => const [])),
            ),
          );
        }
        if (rows.isEmpty) throw const FormatException();
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    }
  }
}
