import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/onboarding/domain/onboarding_answers.dart';
import 'package:mobile/features/onboarding/presentation/viewmodels/onboarding_view_model.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/settings/data/settings_repository_impl.dart';
import 'package:mobile/features/settings/domain/settings_use_cases.dart';

import '../profile/fakes.dart';
import '../settings/fakes.dart';

void main() {
  late MemoryProfiles profiles;
  late MemoryPreferences preferences;
  late DefaultSettingsUseCases settings;
  late OnboardingViewModel model;
  setUp(() {
    profiles = MemoryProfiles();
    preferences = MemoryPreferences();
    settings = DefaultSettingsUseCases(SettingsRepositoryImpl(preferences));
    model = OnboardingViewModel(ProfileUseCases(profiles), settings);
  });
  tearDown(() => model.dispose());

  test('at most two goals; the others stop being pickable', () {
    model.toggleGoal(OnboardingGoal.save);
    model.toggleGoal(OnboardingGoal.budget);
    model.toggleGoal(OnboardingGoal.debt);
    expect(model.goals, [OnboardingGoal.save, OnboardingGoal.budget]);
    expect(model.canPickGoal(OnboardingGoal.debt), isFalse);
    expect(model.canPickGoal(OnboardingGoal.save), isTrue);
    model.toggleGoal(OnboardingGoal.save);
    expect(model.canPickGoal(OnboardingGoal.debt), isTrue);
  });

  test(
    'each step sends only what was answered; skipping sends nothing',
    () async {
      await model.saveGoals();
      await model.saveHabits();
      expect(profiles.onboarding, isEmpty);
      model.toggleGoal(OnboardingGoal.track);
      await model.saveGoals();
      model.pickHabit(TrackingHabit.app);
      await model.saveHabits();
      expect(profiles.onboarding.map((a) => a.toJson()), [
        {
          'goals': ['track'],
        },
        {'trackingHabit': 'app'},
      ]);
    },
  );

  test('a failed save never throws and never blocks the next step', () async {
    profiles.failure = const AuthFailure(AuthError.network);
    model.toggleGoal(OnboardingGoal.track);
    await model.saveGoals();
    expect(profiles.onboarding, isEmpty);
  });

  test('budget keys: no leading zeros, 12 digit cap, delete, suggestions', () {
    model.typeBudget('0');
    expect(model.budget, 0);
    model.typeBudget('1');
    model.typeBudget('000');
    expect(model.budget, 1000);
    model.deleteBudgetDigit();
    expect(model.budget, 100);
    model.setBudget(10000000);
    expect(model.budget, 10000000);
    for (var i = 0; i < 6; i++) {
      model.typeBudget('000');
    }
    expect(model.budget.toString().length, lessThanOrEqualTo(12));
  });

  test(
    'the budget draft is kept on the device only when one was typed',
    () async {
      await model.saveBudgetDraft();
      expect(preferences.value, isNull);
      model.setBudget(15000000);
      await model.saveBudgetDraft();
      final saved = (await settings.load()).getOrElse(
        () => throw StateError('x'),
      );
      expect(saved.budgetDraftMinor, 15000000);
    },
  );

  test(
    'a typed budget is also saved on the account; nothing typed sends nothing',
    () async {
      await model.saveBudgetDraft();
      expect(profiles.onboarding, isEmpty);
      model.setBudget(15000000);
      await model.saveBudgetDraft();
      expect(profiles.onboarding.single.budgetMinor, BigInt.from(15000000));
      expect(profiles.onboarding.single.goals, isNull);
    },
  );
}
