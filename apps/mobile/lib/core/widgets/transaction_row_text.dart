import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'highlighted_text.dart';
import 'tag_chip.dart';

/// Title and second line of a transaction row, with up to two tag chips
/// and optional search highlight.
class TransactionRowText extends StatelessWidget {
  const TransactionRowText({
    required this.title,
    required this.subtitle,
    this.tags = const [],
    this.highlight,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<String> tags;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighlightedText(
          title,
          query: highlight,
          style: FreevaTypography.body.copyWith(
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: HighlightedText(
                subtitle,
                query: highlight,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w400,
                  color: c.textSecondary,
                ),
              ),
            ),
            for (final tag in tags.take(2)) Flexible(child: TagChip(tag)),
          ],
        ),
      ],
    );
  }
}
