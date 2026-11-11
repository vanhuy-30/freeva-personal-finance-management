import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import 'category_suggestion.dart';

/// Category suggestions computed on Freeva's server from the user's own book.
abstract class CategorySuggestRepository {
  /// Guesses a category from a merchant (or a note when there is no
  /// merchant). Right(null) when nothing is confident enough or suggestions
  /// are off. Never saves anything.
  Future<Either<AuthFailure, CategorySuggestion?>> suggest({
    required bool income,
    String? merchant,
    String? note,
  });

  /// Records what the user kept and remembers the merchant under it.
  Future<Either<AuthFailure, Unit>> feedback(SuggestionFeedback feedback);
}
