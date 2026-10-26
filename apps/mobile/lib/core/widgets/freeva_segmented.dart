import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

class FreevaSegment<T> {
  const FreevaSegment(this.value, this.label);

  final T value;
  final String label;
}

/// How the selected segment is drawn.
enum FreevaSegmentedStyle {
  /// Ink pill, white text (composer Chi · Thu · Chuyển).
  ink,

  /// White raised pill (lighter navy in dark mode), ink text (report period).
  raised,
}

/// 2–4 mutually exclusive options on a track; the selected one is a pill.
class FreevaSegmented<T> extends StatelessWidget {
  const FreevaSegmented({
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.expand = false,
    this.compact = false,
    this.style = FreevaSegmentedStyle.ink,
    super.key,
  }) : assert(segments.length >= 2 && segments.length <= 4);

  final List<FreevaSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Fill the row with equal segments (report period) instead of hugging.
  final bool expand;

  /// Card-level variant on the subtle track: 30 high, 12 pt text (trend
  /// range); with [expand], 32 high, 13 pt, padding 12 (Chi · Thu · Ví).
  final bool compact;

  /// Look of the selected pill. Applies to the regular size only.
  final FreevaSegmentedStyle style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final raised = !compact && style == FreevaSegmentedStyle.raised;
    final wide = compact && expand;
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
            constraints: BoxConstraints(
              minHeight: wide ? 32 : (compact ? 30 : 36),
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              horizontal: wide
                  ? 12
                  : compact
                  ? 10
                  : (expand ? 6 : FreevaSpace.s4),
              vertical: compact ? 4 : 6,
            ),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: !on
                  ? Colors.transparent
                  : raised
                  ? c.segmentedRaisedBg
                  : c.segmentedSelectedBg,
              shadows: on && raised ? FreevaElevation.segment : null,
            ),
            child: Text(
              segment.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: FreevaTypography.body.copyWith(
                fontSize: wide ? 13 : (compact ? 12 : 14),
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: !on
                    ? c.textSecondary
                    : raised
                    ? c.textPrimary
                    : c.segmentedSelectedFg,
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
