/// What a person wants from Freeva (first-run question 1, at most two).
enum OnboardingGoal { track, save, budget, debt, emergency, understand }

/// How they manage money today (question 2).
enum TrackingHabit { manual, spreadsheet, app, none }

/// How often they look back at spending (question 2).
enum ReviewCadence { daily, weekly, monthly, rarely }

/// Answers from the first-run questions. Every part is optional: a skipped
/// step sends nothing, and the server keeps what it already has.
class OnboardingAnswers {
  const OnboardingAnswers({this.goals, this.habit, this.cadence});

  final List<OnboardingGoal>? goals;
  final TrackingHabit? habit;
  final ReviewCadence? cadence;

  bool get isEmpty => goals == null && habit == null && cadence == null;

  Map<String, dynamic> toJson() => {
    if (goals != null) 'goals': [for (final g in goals!) g.name],
    if (habit != null) 'trackingHabit': habit!.name,
    if (cadence != null) 'reviewCadence': cadence!.name,
  };
}
