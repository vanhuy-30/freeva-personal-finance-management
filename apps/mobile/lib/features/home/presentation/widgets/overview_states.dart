import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/skeleton.dart';
import 'overview_blocks.dart';

/// Loading: the wash stays with the real "Tổng số dư" label and white 72%
/// blocks instead of numbers. Never shows a fake 0.
class BalanceSkeleton extends StatelessWidget {
  const BalanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      label: s.commonLoading,
      child: ExcludeSemantics(
        child: WashSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: FreevaSize.iconButtonS,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    s.homeTotalBalanceLabel,
                    style: FreevaTypography.bodyS.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                      color: context.colors.balanceCardFg,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: FreevaSpace.s2),
              const SkeletonBox(width: 210, height: 36, onWash: true),
              const SizedBox(height: FreevaSpace.s4),
              const Row(
                children: [
                  Expanded(
                    child: SkeletonBox(
                      height: 58,
                      radius: FreevaRadius.md,
                      onWash: true,
                    ),
                  ),
                  SizedBox(width: FreevaSpace.s2),
                  Expanded(
                    child: SkeletonBox(
                      height: 58,
                      radius: FreevaRadius.md,
                      onWash: true,
                    ),
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
    Widget pair(double height, {double? a, double? b}) => Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: SkeletonBox(width: a, height: height),
          ),
        ),
        const SizedBox(width: FreevaSpace.s3),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SkeletonBox(width: b, height: height),
          ),
        ),
      ],
    );
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                pair(16, a: 110, b: 90),
                const SizedBox(height: 14),
                const SkeletonBox(height: 10, radius: FreevaRadius.full),
                const SizedBox(height: 14),
                pair(12),
                const SizedBox(height: 10),
                pair(12),
              ],
            ),
          ),
          const SizedBox(height: OverviewBlocks.gap),
          const FreevaCard(
            list: true,
            padding: EdgeInsets.symmetric(
              horizontal: FreevaSpace.s4,
              vertical: FreevaSpace.s1,
            ),
            child: SkeletonRows(
              count: 2,
              padding: EdgeInsets.symmetric(vertical: FreevaSpace.s3),
              dividers: true,
              fixedBlocks: true,
            ),
          ),
        ],
      ),
    );
  }
}
