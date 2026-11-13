import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/category_suggest_repository.dart';
import '../domain/category_suggestion.dart';

@LazySingleton(as: CategorySuggestRepository)
class CategorySuggestRepositoryImpl implements CategorySuggestRepository {
  CategorySuggestRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static const _base = 'category-suggestions';

  @override
  Future<Either<AuthFailure, CategorySuggestion?>> suggest({
    required bool income,
    String? merchant,
    String? note,
  }) async {
    final result = await _api.request(
      'POST',
      '$_base/suggest',
      body: {
        'merchant': merchant,
        'note': note,
        'type': income ? 'income' : 'expense',
      },
    );
    return result.fold(left, (json) {
      try {
        return right(_suggestion(json['suggestion']));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  CategorySuggestion? _suggestion(Object? raw) {
    if (raw == null) return null;
    final json = raw as Map<String, dynamic>;
    final category = json['category'] as Map<String, dynamic>;
    return CategorySuggestion(
      categoryId: category['id'] as String,
      categoryName: category['name'] as String,
      iconToken: category['iconToken'] as String?,
      colorToken: category['colorToken'] as String?,
      source: SuggestionSource.values.byName(json['source'] as String),
      matchCount: (json['matchCount'] as num).toInt(),
      confidencePercent: (json['confidencePercent'] as num?)?.toInt(),
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> feedback(
    SuggestionFeedback feedback,
  ) async {
    final result = await _api.request(
      'POST',
      '$_base/feedback',
      body: {
        'merchant': feedback.merchant,
        'suggestedCategoryId': feedback.suggestedCategoryId,
        'chosenCategoryId': feedback.chosenCategoryId,
        'source': feedback.source.name,
        'surface': feedback.surface.name,
      },
    );
    return result.map((_) => unit);
  }
}
