import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/goal.dart';
import 'goal_look.dart';

/// One goal in the list: icon, name, `đã có / đích`, % or a status tag, the
/// bar and one line of text. Overdue and reached show a tag instead of %.
class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.goal,
    required this.digits,
    required this.onTap,
    super.key,
  });

  final Goal goal;
  final int digits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt value) => formatMoneyText(value, digits, locale);
    final tag = switch (goal.status) {
      GoalStatus.overdue => (s.goalsOverdue, c.statusDangerBg, c.statusDanger),
      GoalStatus.reached => (
        s.goalsReached,
        c.statusSuccessBg,
        c.statusSuccess,
      ),
      GoalStatus.active => null,
    };
    return FreevaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GoalIconTile(kind: goal.kind),
              const SizedBox(width: FreevaSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.titleM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${money(goal.currentMinor)} / ${money(goal.targetMinor)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FreevaTypography.label.copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: FreevaSpace.s3),
              if (tag == null)
                Text(
                  s.goalPercent('${goal.percent}'),
                  style: FreevaTypography.titleM.copyWith(color: c.textPrimary),
                )
              else
                _Tag(label: tag.$1, fill: tag.$2, ink: tag.$3),
            ],
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaProgressBar(
            value: goal.progress,
            color: goalBarColor(context, goal),
            semanticsLabel: goal.name,
          ),
          const SizedBox(height: FreevaSpace.s3),
          Text(
            goalLine(s, goal, digits, locale),
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.fill, required this.ink});

  final String label;
  final Color fill;
  final Color ink;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(FreevaRadius.full),
    ),
    child: Text(
      label,
      maxLines: 1,
      style: FreevaTypography.label.copyWith(color: ink),
    ),
  );
}
