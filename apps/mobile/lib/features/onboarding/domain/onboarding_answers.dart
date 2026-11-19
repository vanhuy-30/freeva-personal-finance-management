import '../../profile/domain/declared_income.dart';

/// What a person wants from Freeva (first-run question 1, any number), in
/// the board's order. Server codes are the names.
enum OnboardingGoal { track, budget, save, debt, assets, habits }

/// Answers from the first-run questions. Every part is optional: a skipped
/// step sends nothing, and the server keeps what it already has.
class OnboardingAnswers {
  const OnboardingAnswers({this.goals, this.declaredIncome});

  final List<OnboardingGoal>? goals;

  /// Income band in the profile currency.
  final DeclaredIncome? declaredIncome;

  bool get isEmpty => goals == null && declaredIncome == null;

  Map<String, dynamic> toJson() => {
    if (goals != null) 'goals': [for (final g in goals!) g.name],
    if (declaredIncome != null) 'declaredIncome': declaredIncome!.toJson(),
  };
}
