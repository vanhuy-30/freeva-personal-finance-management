/// A merchant the app remembers for category suggestions (PRD-P5-E01):
/// "Highlands Coffee" goes to "Cà phê". Shown on Gợi ý tự động so the user can
/// forget it.
class MerchantMapping {
  const MerchantMapping({
    required this.id,
    required this.merchant,
    required this.categoryId,
    required this.categoryName,
    required this.updatedAt,
    this.iconToken,
    this.colorToken,
  });

  final String id;
  final String merchant;
  final String categoryId;
  final String categoryName;

  /// Category icon key (same as on the category); null uses the default glyph.
  final String? iconToken;
  final String? colorToken;
  final DateTime updatedAt;
}
