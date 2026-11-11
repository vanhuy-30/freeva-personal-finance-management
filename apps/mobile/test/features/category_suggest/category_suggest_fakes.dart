import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/category_suggest/domain/category_suggest_repository.dart';
import 'package:mobile/features/category_suggest/domain/category_suggestion.dart';

/// Board R.1: "Xếp vào Cà phê?" / "Như 8 lần trước ở đây".
const boardSuggestion = CategorySuggestion(
  categoryId: 'coffee',
  categoryName: 'Cà phê',
  iconToken: 'coffee',
  source: SuggestionSource.history,
  matchCount: 8,
  confidencePercent: 89,
);

class SuggestCall {
  SuggestCall(this.income, this.merchant, this.note);
  final bool income;
  final String? merchant;
  final String? note;
  final completer = Completer<Either<AuthFailure, CategorySuggestion?>>();
}

/// Answers right away with [answer] unless [hold] is set; then each call
/// waits until the test completes it.
class FakeCategorySuggest implements CategorySuggestRepository {
  CategorySuggestion? answer = boardSuggestion;
  AuthFailure? failure;
  bool hold = false;
  bool throwOnFeedback = false;
  final calls = <SuggestCall>[];
  final feedbacks = <SuggestionFeedback>[];

  @override
  Future<Either<AuthFailure, CategorySuggestion?>> suggest({
    required bool income,
    String? merchant,
    String? note,
  }) {
    final call = SuggestCall(income, merchant, note);
    calls.add(call);
    if (!hold) {
      call.completer.complete(failure == null ? right(answer) : left(failure!));
    }
    return call.completer.future;
  }

  @override
  Future<Either<AuthFailure, Unit>> feedback(SuggestionFeedback value) async {
    if (throwOnFeedback) throw StateError('offline');
    feedbacks.add(value);
    return failure == null ? right(unit) : left(failure!);
  }
}
