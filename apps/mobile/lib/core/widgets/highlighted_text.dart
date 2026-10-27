import 'package:flutter/material.dart';

import '../text/vietnamese_fold.dart';
import '../theme/theme_context.dart';

/// Text with the parts matching [query] (case and diacritics ignored) set in
/// bold on a `tint.blue` pill (radius 4, 2 px side padding), for search
/// results.
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
    final mark = style.copyWith(fontWeight: FontWeight.w700);
    final markBg = context.colors.tintBlue;
    final spans = <InlineSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) spans.add(TextSpan(text: text.substring(at, start)));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: markBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(text.substring(start, end), style: mark),
          ),
        ),
      );
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
