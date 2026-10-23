/// Lower-case and strip Vietnamese diacritics so "pho" matches "Phở".
/// Keeps the string length (one char in, one char out), so match offsets
/// found in the folded text are valid in the original.
String foldVietnamese(String text) {
  final out = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    out.write(_fold[char] ?? char);
  }
  return out.toString();
}

/// Ranges of [text] that match [query] ignoring case and diacritics.
List<(int, int)> foldedMatches(String text, String query) {
  final needle = foldVietnamese(query.trim());
  if (needle.isEmpty) return const [];
  final hay = foldVietnamese(text);
  // Folding is 1:1 per UTF-16 unit only for BMP text; bail out otherwise.
  if (hay.length != text.length) return const [];
  final ranges = <(int, int)>[];
  var start = hay.indexOf(needle);
  while (start >= 0) {
    ranges.add((start, start + needle.length));
    start = hay.indexOf(needle, start + needle.length);
  }
  return ranges;
}

const _groups = {
  'a': 'àáảãạăằắẳẵặâầấẩẫậ',
  'e': 'èéẻẽẹêềếểễệ',
  'i': 'ìíỉĩị',
  'o': 'òóỏõọôồốổỗộơờớởỡợ',
  'u': 'ùúủũụưừứửữự',
  'y': 'ỳýỷỹỵ',
  'd': 'đ',
};

final Map<String, String> _fold = {
  for (final entry in _groups.entries)
    for (final char in entry.value.split('')) char: entry.key,
};
