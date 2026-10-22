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
    super.key,
  }) : assert(segments.length >= 2 && segments.length <= 4);

  final List<FreevaSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Fill the row with equal segments (report period) instead of hugging.
  final bool expand;

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
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: on ? c.segmentedSelectedBg : Colors.transparent,
            ),
            child: Text(
              segment.label,
              maxLines: 1,
              style: FreevaTypography.body.copyWith(
                fontSize: 14,
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
      padding: const EdgeInsets.all(FreevaSpace.s1),
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: c.segmentedTrack,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (final segment in segments) item(segment)],
      ),
    );
  }
}
