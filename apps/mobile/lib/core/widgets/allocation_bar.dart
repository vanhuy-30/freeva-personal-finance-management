import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

class AllocationPart {
  const AllocationPart(this.weight, this.color);

  final double weight;
  final Color color;
}

/// Allocation bar: rounded segments with a 3 pt gap, 10 high. Callers pass
/// colours in data order (data.1 → data.4, then `data.muted` for "Other").
class AllocationBar extends StatelessWidget {
  const AllocationBar({required this.parts, this.semanticsLabel, super.key});

  final List<AllocationPart> parts;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final visible = parts.where((p) => p.weight > 0).toList();
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 10,
        child: visible.isEmpty
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: c.bgTrack,
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: const SizedBox.expand(),
              )
            : Row(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: (visible[i].weight * 1000).round().clamp(
                        1,
                        1 << 30,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: visible[i].color,
                          borderRadius: BorderRadius.circular(
                            FreevaRadius.full,
                          ),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
