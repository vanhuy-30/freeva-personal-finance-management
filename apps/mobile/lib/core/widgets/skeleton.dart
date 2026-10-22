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
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({this.count = 3, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).commonLoading,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const SkeletonBox(width: 40, height: 40, radius: 20),
                    const SizedBox(width: FreevaSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                    SkeletonBox(width: i.isEven ? 64 : 56, height: 12),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
