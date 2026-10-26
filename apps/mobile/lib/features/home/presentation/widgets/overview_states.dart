import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';

/// Loading: the wash stays, with white 72% blocks instead of numbers. Never
/// shows a fake 0.
class BalanceSkeleton extends StatelessWidget {
  const BalanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: S.of(context).commonLoading,
      child: const ExcludeSemantics(
        child: WashSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 14, onWash: true),
              SizedBox(height: FreevaSpace.s3),
              SkeletonBox(width: 220, height: 40, onWash: true),
              SizedBox(height: FreevaSpace.s4),
              Row(
                children: [
                  Expanded(
                    child: SkeletonBox(height: 56, radius: 16, onWash: true),
                  ),
                  SizedBox(width: FreevaSpace.s2),
                  Expanded(
                    child: SkeletonBox(height: 56, radius: 16, onWash: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder for the spending block and recent list.
class BlocksSkeleton extends StatelessWidget {
  const BlocksSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 14),
                SkeletonBox(height: 10, radius: 999),
                SizedBox(height: 14),
                SkeletonBox(width: 200, height: 12),
              ],
            ),
          ),
          SizedBox(height: FreevaSpace.s6),
          FreevaCard(
            list: true,
            padding: EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
            child: SkeletonRows(),
          ),
        ],
      ),
    );
  }
}
