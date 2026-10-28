import 'package:flutter/foundation.dart';

import '../../../budgets/domain/budget.dart';
import '../../../budgets/domain/budget_use_cases.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../settings/domain/app_preferences.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../domain/onboarding_answers.dart';

/// Choices on the first-run questions. Saving is best effort: the answers
/// only personalise the app, so a failed save never holds anyone on a screen.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel(this._profile, this._settings, [this._budgets]);

  final ProfileUseCases _profile;
  final SettingsUseCases _settings;
  final BudgetUseCases? _budgets;

  static const maxGoals = 2;
  static const maxBudgetDigits = 12;

  /// Quick amounts under the budget field, in VND.
  static const budgetSuggestions = [5000000, 10000000, 15000000, 20000000];

  final List<OnboardingGoal> goals = [];
  TrackingHabit? habit;
  ReviewCadence? cadence;
  String _budgetDigits = '';

  bool canPickGoal(OnboardingGoal goal) =>
      goals.contains(goal) || goals.length < maxGoals;

  void toggleGoal(OnboardingGoal goal) {
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else if (goals.length < maxGoals) {
      goals.add(goal);
    }
    notifyListeners();
  }

  void pickHabit(TrackingHabit value) {
    habit = habit == value ? null : value;
    notifyListeners();
  }

  void pickCadence(ReviewCadence value) {
    cadence = cadence == value ? null : value;
    notifyListeners();
  }

  /// Budget in VND, 0 when nothing is typed.
  int get budget => int.tryParse(_budgetDigits) ?? 0;

  void typeBudget(String keys) {
    var next = _budgetDigits + keys;
    next = next.replaceFirst(RegExp(r'^0+'), '');
    if (next.length > maxBudgetDigits) return;
    _budgetDigits = next;
    notifyListeners();
  }

  void deleteBudgetDigit() {
    if (_budgetDigits.isEmpty) return;
    _budgetDigits = _budgetDigits.substring(0, _budgetDigits.length - 1);
    notifyListeners();
  }

  void setBudget(int value) {
    _budgetDigits = value > 0 ? '$value' : '';
    notifyListeners();
  }

  Future<void> saveGoals() => _saveAnswers(
    OnboardingAnswers(goals: goals.isEmpty ? null : List.of(goals)),
  );

  Future<void> saveHabits() =>
      _saveAnswers(OnboardingAnswers(habit: habit, cadence: cadence));

  Future<void> _saveAnswers(OnboardingAnswers answers) async {
    // Nothing waits on this: a left value is dropped on purpose.
    await _profile.saveOnboarding(answers);
  }

  /// Tries to create the monthly budget on the server; keeps a device draft
  /// when the API is unavailable or a budget already exists.
  Future<void> saveBudgetDraft() async {
    if (budget <= 0) return;
    final amount = BigInt.from(budget);
    final budgets = _budgets;
    if (budgets != null) {
      final current = await budgets.current();
      final created = await current.fold((_) async => false, (value) async {
        if (value.budget != null) return true;
        final put = await budgets.put(
          BudgetDraft(
            limitMinor: amount,
            alertThresholds: List.of(defaultAlertThresholds),
            categories: const [],
          ),
        );
        return put.isRight();
      });
      if (created) {
        final loaded = await _settings.load();
        await loaded.fold((_) async {}, (prefs) async {
          if (prefs.budgetDraftMinor == null) return;
          await _settings.save(prefs.copyWith(budgetDraftMinor: null));
        });
        return;
      }
    }
    final loaded = await _settings.load();
    final prefs = loaded.fold<AppPreferences?>((_) => null, (value) => value);
    if (prefs == null) return;
    await _settings.save(prefs.copyWith(budgetDraftMinor: budget));
  }
}
