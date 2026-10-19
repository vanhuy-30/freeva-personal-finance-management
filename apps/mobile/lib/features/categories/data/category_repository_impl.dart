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
    clientId: json['clientId'] as String? ?? '',
    colorToken: json['colorToken'] as String?,
    iconToken: json['iconToken'] as String?,
    isSystem: json['isSystem'] as bool? ?? false,
    archived: json['archivedAt'] != null,
    version: json['version'] as int? ?? 1,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
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

  Future<AuthFailure?> _seed() async {
    final seeded = await _api.request('POST', 'categories/defaults');
    return seeded.fold((error) => error, (_) => null);
  }

  Future<Either<AuthFailure, List<FinanceCategory>>> _pages(
    String status,
  ) async {
    final items = <FinanceCategory>[];
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'categories?status=$status&pageSize=100&page=$page',
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
  Future<Either<AuthFailure, CategoryCatalog>> load() async {
    final seedError = await _seed();
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
    final pages = await _pages('active');
    return pages.fold(
      left,
      (items) => right(
        CategoryCatalog(
          all: items,
          recent: List.unmodifiable(recent.getOrElse(() => const [])),
        ),
      ),
    );
  }

  CategoryOptions _options(Map<String, dynamic> json) => CategoryOptions(
    colorTokens: List<String>.unmodifiable(
      (json['colorTokens'] as List).cast<String>(),
    ),
    iconTokens: List<String>.unmodifiable(
      (json['iconTokens'] as List).cast<String>(),
    ),
  );

  @override
  Future<Either<AuthFailure, CategoryManagement>> manage() async {
    final seedError = await _seed();
    if (seedError != null) return left(seedError);
    final pages = await _pages('all');
    final pageError = pages.fold<AuthFailure?>((error) => error, (_) => null);
    if (pageError != null) return left(pageError);
    final options = await _request('GET', 'categories/options', _options);
    return options.fold(
      left,
      (catalog) => right(
        CategoryManagement(
          items: pages.getOrElse(() => const []),
          options: catalog,
        ),
      ),
    );
  }

  Map<String, dynamic> _body(
    CategoryDraft draft, {
    FinanceCategory? category,
    required String clientId,
  }) {
    final name = draft.name.trim();
    if (category == null) {
      return {
        'clientId': clientId,
        'name': name,
        if (draft.parentId != null) 'parentId': draft.parentId,
        if (draft.colorToken != null) 'colorToken': draft.colorToken,
        if (draft.iconToken != null) 'iconToken': draft.iconToken,
      };
    }
    return {
      'version': category.version,
      'name': name,
      if (draft.parentId != category.parentId) 'parentId': draft.parentId,
      if (draft.colorToken != category.colorToken)
        'colorToken': draft.colorToken,
      if (draft.iconToken != category.iconToken) 'iconToken': draft.iconToken,
    };
  }

  @override
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft, {
    FinanceCategory? category,
    required String clientId,
  }) => _request(
    category == null ? 'POST' : 'PATCH',
    category == null ? 'categories' : 'categories/${category.id}',
    _parse,
    body: _body(draft, category: category, clientId: clientId),
  );

  @override
  Future<Either<AuthFailure, FinanceCategory>> update(
    FinanceCategory category, {
    required bool archived,
  }) => _request(
    'PATCH',
    'categories/${category.id}',
    _parse,
    body: {'version': category.version, 'archived': archived},
  );

  @override
  Future<Either<AuthFailure, void>> delete(
    FinanceCategory category, {
    String? replacementCategoryId,
  }) async {
    final path = Uri(
      path: 'categories/${category.id}',
      queryParameters: {
        'version': '${category.version}',
        if (replacementCategoryId != null)
          'replacementCategoryId': replacementCategoryId,
      },
    ).toString();
    final result = await _api.request('DELETE', path);
    return result.fold(left, (_) => right(null));
  }
}
