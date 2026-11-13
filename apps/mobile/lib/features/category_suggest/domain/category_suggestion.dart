/// Where a category suggestion came from (BE-P5-E03).
enum SuggestionSource {
  /// A merchant the user remembered.
  remembered,

  /// The user's own history at that merchant (or with that note).
  history,

  /// The shared list of common merchants.
  common,
}

/// What surface the user saw the suggestion on.
enum SuggestionSurface { entry, import }

/// "Xếp vào Cà phê?" while recording a transaction (MOB-P5-E03, board R.1).
class CategorySuggestion {
  const CategorySuggestion({
    required this.categoryId,
    required this.categoryName,
    required this.source,
    required this.matchCount,
    this.iconToken,
    this.colorToken,
    this.confidencePercent,
  });

  final String categoryId;
  final String categoryName;

  /// Category icon key; null uses the default glyph.
  final String? iconToken;
  final String? colorToken;
  final SuggestionSource source;

  /// Earlier transactions here in that category ("Như 8 lần trước ở đây");
  /// 0 for the common list.
  final int matchCount;
  final int? confidencePercent;
}

/// What the user kept after a suggestion; sent once the transaction is saved.
class SuggestionFeedback {
  const SuggestionFeedback({
    required this.suggestedCategoryId,
    required this.chosenCategoryId,
    required this.source,
    required this.surface,
    this.merchant,
  });

  final String? merchant;
  final String suggestedCategoryId;
  final String chosenCategoryId;
  final SuggestionSource source;
  final SuggestionSurface surface;

  /// The user kept the suggested category.
  bool get accepted => suggestedCategoryId == chosenCategoryId;
}
