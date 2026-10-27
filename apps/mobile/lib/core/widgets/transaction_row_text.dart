import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';
import 'highlighted_text.dart';
import 'tag_chip.dart';

/// Title and second line of a transaction row, with up to two tag chips
/// and optional search highlight. Title 15/1.2, second line 12/1.25, no gap;
/// the second line is dropped when there is nothing to show.
class TransactionRowText extends StatelessWidget {
  const TransactionRowText({
    required this.title,
    required this.subtitle,
    this.tags = const [],
    this.highlight,
    this.subtitleWidget,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<String> tags;
  final String? highlight;

  /// Replaces the second line (sync or pending marks, see
  /// [TransactionRowNote]).
  final Widget? subtitleWidget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final second =
        subtitleWidget ??
        (subtitle.isEmpty && tags.isEmpty
            ? null
            : Row(
                children: [
                  Flexible(
                    child: HighlightedText(
                      subtitle,
                      query: highlight,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  for (final tag in tags.take(2)) Flexible(child: TagChip(tag)),
                ],
              ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HighlightedText(
          title,
          query: highlight,
          style: FreevaTypography.body.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: c.textPrimary,
          ),
        ),
        if (second != null) second,
      ],
    );
  }
}

/// Second-line mark: 12 px glyph, 4 gap, 12 px text in [color]
/// (default `text.secondary`). Pending rows pass `status.info` and a clock.
class TransactionRowNote extends StatelessWidget {
  const TransactionRowNote({
    required this.icon,
    required this.text,
    this.color,
    this.bold = false,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color? color;

  /// Weight 600 ("Cần xem lại").
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.colors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 12, color: fg),
        const SizedBox(width: FreevaSpace.s1),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FreevaTypography.label.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              height: 1.25,
              color: fg,
            ),
          ),
        ),
      ],
    );
  }
}
