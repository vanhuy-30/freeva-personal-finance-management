import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/theme_context.dart';
import '../theme/tokens.g.dart';

/// Placeholder block shaped like the content it stands for. `onWash` uses
/// white 72% so the balance-card wash stays visible.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    required this.height,
    this.radius = 8,
    this.onWash = false,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;
  final bool onWash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: onWash ? c.bgSurface.withValues(alpha: .72) : c.bgSkeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for transaction rows: round icon, two lines, an amount.
/// The Overview loading board uses `padding: EdgeInsets.symmetric(vertical:
/// 12)`, `dividers: true`, `fixedBlocks: true`.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({
    this.count = 3,
    this.padding = const EdgeInsets.symmetric(vertical: 10),
    this.dividers = false,
    this.fixedBlocks = false,
    super.key,
  });

  final int count;

  /// Padding of each row.
  final EdgeInsetsGeometry padding;

  /// 1 px `border.divider` line between rows.
  final bool dividers;

  /// Board block sizes: title 14 high, 120/96 wide; second line 10 high,
  /// 90/80 wide; amount 14 high, 64/56 wide. Otherwise the lines are
  /// fractions of the row width.
  final bool fixedBlocks;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: S.of(context).commonLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              Container(
                padding: padding,
                decoration: dividers && i > 0
                    ? BoxDecoration(
                        border: Border(top: BorderSide(color: c.borderDivider)),
                      )
                    : null,
                child: Row(
                  children: [
                    const SkeletonBox(width: 40, height: 40, radius: 20),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: fixedBlocks
                            ? [
                                SkeletonBox(
                                  width: i.isEven ? 120 : 96,
                                  height: 14,
                                ),
                                const SizedBox(height: 6),
                                SkeletonBox(
                                  width: i.isEven ? 90 : 80,
                                  height: 10,
                                ),
                              ]
                            : [
                                FractionallySizedBox(
                                  widthFactor: i.isEven ? .6 : .5,
                                  child: const SkeletonBox(height: 12),
                                ),
                                const SizedBox(height: 6),
                                FractionallySizedBox(
                                  widthFactor: i.isEven ? .4 : .35,
                                  child: const SkeletonBox(height: 10),
                                ),
                              ],
                      ),
                    ),
                    const SizedBox(width: FreevaSpace.s3),
                    SkeletonBox(
                      width: i.isEven ? 64 : 56,
                      height: fixedBlocks ? 14 : 12,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
