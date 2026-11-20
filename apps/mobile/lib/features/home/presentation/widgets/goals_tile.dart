import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../goals/domain/goal.dart';
import '../../../goals/presentation/widgets/goal_look.dart';
import 'glance_painters.dart';
import 'glance_tile.dart';

/// "Mục tiêu": up to two small rings with the percent inside and the name
/// under each. Opens the goal list.
class GoalsTile extends StatelessWidget {
  const GoalsTile({required this.goals, super.key});

  /// Active goals, not empty; the first two are shown.
  final List<Goal> goals;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final shown = goals.take(2).toList();
    String percent(Goal goal) => '${(goal.percentBps / 100).floor()}%';
    return GlanceTile(
      semanticsLabel: [
        s.homeGoalsTile,
        for (final goal in shown) '${goal.name} ${percent(goal)}',
      ].join(', '),
      onTap: () => context.push('/me/goals'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlanceHeader(
            icon: LucideIcons.target,
            label: s.homeGoalsTile,
            bg: c.tintCyan,
            fg: c.tintCyanFg,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final goal in shown)
                Expanded(
                  child: Column(
                    children: [
                      ProgressRing(
                        size: 52,
                        stroke: 6,
                        value: goal.percentBps / 10000,
                        color: goalBarColor(context, goal),
                        track: c.bgTrack,
                        child: Text(
                          percent(goal),
                          style: FreevaTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        goal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: glanceNote(context),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
