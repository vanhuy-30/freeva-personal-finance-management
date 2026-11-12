import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../spend_forecast/presentation/widgets/forecast_chip.dart';
import '../../domain/goal.dart';
import '../../domain/goal_forecast.dart';
import 'goal_forecast_text.dart';
import 'goal_forecast_timeline.dart';

/// T.1 card under the goal tiles: "Với mức góp gần đây / Dự kiến đạt
/// MM/yyyy", late/early chip, the Hôm nay → Hạn → Dự kiến timeline and the
/// recent average. Before any contribution it only says so.
class GoalForecastCard extends StatelessWidget {
  const GoalForecastCard({
    required this.forecast,
    required this.goal,
    required this.today,
    required this.digits,
    super.key,
  });

  /// [GoalForecastOk] or [GoalForecastInsufficient].
  final GoalForecast forecast;
  final Goal goal;

  /// `yyyy-MM-dd`; the timeline starts at its month.
  final String today;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final muted = FreevaTypography.bodyS.copyWith(color: c.textSecondary);
    final title = FreevaTypography.titleL.copyWith(
      height: 1.2,
      color: c.textPrimary,
    );
    final f = forecast;
    if (f is! GoalForecastOk) {
      return FreevaCard(
        padding: const EdgeInsets.all(18),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.goalForecastNotYet, style: title),
              const SizedBox(height: FreevaSpace.s1),
              Text(s.goalForecastNotYetBody, style: muted),
            ],
          ),
        ),
      );
    }
    final chip = goalForecastChip(s, f);
    final target = f.targetMonth;
    final timeline = target == null
        ? null
        : goalTimeline(today: today, target: target, expected: f.expectedMonth);
    final line = goalForecastLine(
      s,
      f,
      goal,
      (v) => formatMoneyText(v, digits, locale),
    );
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.goalForecastPace,
                        style: FreevaTypography.label.copyWith(
                          fontWeight: FontWeight.w400,
                          color: c.textSecondary,
                        ),
                      ),
                      Text(
                        s.goalForecastExpected(
                          forecastMonthLabel(f.expectedMonth),
                        ),
                        style: title,
                      ),
                    ],
                  ),
                ),
                if (chip != null) ...[
                  const SizedBox(width: FreevaSpace.s2),
                  ForecastChip(label: chip.$1, tone: chip.$2),
                ],
              ],
            ),
          ),
          if (timeline != null) ...[
            const SizedBox(height: 14),
            Semantics(
              container: true,
              label: _timelineLabel(s, timeline),
              child: ExcludeSemantics(
                child: GoalForecastTimeline(timeline: timeline),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, thickness: 1, color: c.borderDivider),
          const SizedBox(height: FreevaSpace.s3),
          Text(line, style: muted),
        ],
      ),
    );
  }

  static String _timelineLabel(S s, GoalTimeline t) => [
    for (final mark in t.marks)
      '${switch (mark.kind) {
        GoalMarkKind.today => s.goalForecastToday,
        GoalMarkKind.due => s.goalForecastDue,
        GoalMarkKind.expected => s.goalForecastWhen,
      }} ${mark.month}',
  ].join(', ');
}
