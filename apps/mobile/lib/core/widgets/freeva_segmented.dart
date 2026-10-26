import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

class FreevaSegment<T> {
  const FreevaSegment(this.value, this.label);

  final T value;
  final String label;
}

/// 2–4 mutually exclusive options on a track; the selected one is an ink pill.
class FreevaSegmented<T> extends StatelessWidget {
  const FreevaSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.compact = false,
    super.key,
  }) : assert(segments.length >= 2 && segments.length <= 4);

  final List<FreevaSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Fill the row with equal segments (report period) instead of hugging.
  final bool expand;

  /// Card-level variant (trend range, Chi · Thu · Ví): 30 high, 12 pt text,
  /// on the subtle track.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget item(FreevaSegment<T> segment) {
      final on = segment.value == selected;
      final child = Semantics(
        selected: on,
        button: true,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(segment.value),
          child: AnimatedContainer(
            duration: FreevaMotion.fast,
            curve: FreevaMotion.standard,
            // Grows instead of clipping when large text needs two lines.
            constraints: BoxConstraints(minHeight: compact ? 30 : 36),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : (expand ? 6 : 18),
              vertical: compact ? 4 : 6,
            ),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: on ? c.segmentedSelectedBg : Colors.transparent,
            ),
            child: Text(
              segment.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: FreevaTypography.body.copyWith(
                fontSize: compact ? 12 : 14,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: on ? c.segmentedSelectedFg : c.textSecondary,
              ),
            ),
          ),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    return Container(
      padding: EdgeInsets.all(compact ? 3 : FreevaSpace.s1),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: compact ? c.bgSubtle : c.segmentedTrack,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final segment in segments) item(segment)],
      ),
    );
  }
}
