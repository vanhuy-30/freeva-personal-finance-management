import 'package:flutter/material.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Progress bar (credit limit, budget). 8 high on the track colour.
class FreevaProgressBar extends StatelessWidget {
  const FreevaProgressBar({
    required this.value,
    this.color,
    this.trackColor,
    this.height = 8,
    this.semanticsLabel,
    super.key,
  });

  /// 0–1; values outside are clamped.
  final double value;
  final Color? color;

  /// Track colour; default `bg.track`.
  final Color? trackColor;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: semanticsLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FreevaRadius.full),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: trackColor ?? c.bgTrack),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0, 1).toDouble(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? c.data1,
                    borderRadius: BorderRadius.circular(FreevaRadius.full),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
