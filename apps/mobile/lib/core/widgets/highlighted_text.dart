import 'package:flutter/material.dart';

import '../text/vietnamese_fold.dart';
import '../theme/theme_context.dart';

/// Text with the parts matching [query] (case and diacritics ignored) on a
/// `tint.blue` background, for search results.
class HighlightedText extends StatelessWidget {
  const HighlightedText(
    this.text, {
    required this.style,
    this.query,
    super.key,
  });

  final String text;
  final String? query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final ranges = query == null
        ? const <(int, int)>[]
        : foldedMatches(text, query!);
    if (ranges.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final mark = style.copyWith(backgroundColor: context.colors.tintBlue);
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(TextSpan(text: text.substring(start, end), style: mark));
      at = end;
    }
    if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
