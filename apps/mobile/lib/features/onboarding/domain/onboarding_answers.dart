/// What a person wants from Freeva (first-run question 1, at most two).
enum OnboardingGoal { track, save, budget }

/// Answers from the first-run questions. Every part is optional: a skipped
/// step sends nothing, and the server keeps what it already has.
class OnboardingAnswers {
  const OnboardingAnswers({this.goals, this.monthlyIncomeMinor});

  final List<OnboardingGoal>? goals;

  /// Monthly income in minor units of the profile currency; positive.
  final BigInt? monthlyIncomeMinor;

  bool get isEmpty => goals == null && monthlyIncomeMinor == null;

  Map<String, dynamic> toJson() => {
    if (goals != null) 'goals': [for (final g in goals!) g.name],
    if (monthlyIncomeMinor != null)
      'monthlyIncomeMinor': monthlyIncomeMinor.toString(),
  };
}
