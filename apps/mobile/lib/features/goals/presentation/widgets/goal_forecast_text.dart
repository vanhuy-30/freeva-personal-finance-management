import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../spend_forecast/presentation/widgets/spend_forecast_labels.dart';
import '../../domain/goal.dart';
import '../../domain/goal_forecast.dart';

/// `yyyy-MM` (or `yyyy-MM-dd`) → `MM/yyyy`, as the goal tiles show months.
String forecastMonthLabel(String month) =>
    '${month.substring(5, 7)}/${month.substring(0, 4)}';

/// "Trễ n tháng" / "Sớm n tháng" / "Kịp hạn"; null without a target date.
(String, ForecastTone)? goalForecastChip(S s, GoalForecastOk f) =>
    switch (f.monthsLate) {
      null => null,
      final n when n > 0 => (s.goalForecastLate(n), ForecastTone.warning),
      final n when n < 0 => (s.goalForecastEarly(-n), ForecastTone.success),
      _ => (s.goalForecastOnTime, ForecastTone.success),
    };

/// Bottom line: the recent average, and when late what it would take each
/// month to make the date.
String goalForecastLine(
  S s,
  GoalForecastOk f,
  Goal goal,
  String Function(BigInt) money,
) {
  final average = s.goalForecastAverage(f.months, money(f.averageMonthlyMinor));
  final need = goal.requiredPerMonthMinor;
  final late = (f.monthsLate ?? 0) > 0;
  if (!late || need == null || need <= BigInt.zero) return average;
  return '$average ${s.goalForecastCatchUp(money(need))}';
}

/// One dot on the T.1 timeline.
enum GoalMarkKind { today, due, expected }

typedef GoalMark = ({GoalMarkKind kind, double at, String month});

/// The T.1 timeline: dots at 0..1 and how far the on-time (primary) part
/// runs; past it, the track is dashed when [late].
typedef GoalTimeline = ({List<GoalMark> marks, double solid, bool late});

/// Hôm nay → Hạn → Dự kiến (or Hôm nay → Dự kiến → Hạn when early), the
/// middle one at its share of the months to the last. On time: one dot at
/// the end. A date already passed leaves out Hạn.
GoalTimeline goalTimeline({
  required String today,
  required String target,
  required String expected,
}) {
  int index(String month) =>
      int.parse(month.substring(0, 4)) * 12 + int.parse(month.substring(5, 7));
  final now = index(today);
  final due = index(target);
  final then = index(expected);
  final todayMark = (
    kind: GoalMarkKind.today,
    at: 0.0,
    month: forecastMonthLabel(today),
  );
  final expectedMark = (
    kind: GoalMarkKind.expected,
    month: forecastMonthLabel(expected),
  );
  final dueMark = (kind: GoalMarkKind.due, month: forecastMonthLabel(target));
  if (due <= now) {
    return (
      marks: [
        todayMark,
        (kind: expectedMark.kind, at: 1.0, month: expectedMark.month),
      ],
      solid: 0,
      late: then > due,
    );
  }
  if (then == due) {
    return (
      marks: [
        todayMark,
        (kind: expectedMark.kind, at: 1.0, month: expectedMark.month),
      ],
      solid: 1,
      late: false,
    );
  }
  final last = then > due ? then : due;
  final middle = ((then > due ? due : then) - now) / (last - now);
  final at = middle.clamp(0.0, 1.0);
  if (then > due) {
    return (
      marks: [
        todayMark,
        (kind: dueMark.kind, at: at, month: dueMark.month),
        (kind: expectedMark.kind, at: 1.0, month: expectedMark.month),
      ],
      solid: at,
      late: true,
    );
  }
  return (
    marks: [
      todayMark,
      (kind: expectedMark.kind, at: at, month: expectedMark.month),
      (kind: dueMark.kind, at: 1.0, month: dueMark.month),
    ],
    solid: at,
    late: false,
  );
}
