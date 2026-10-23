import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../onboarding/presentation/viewmodels/onboarding_view_model.dart';
import '../../../onboarding/presentation/widgets/budget_step.dart';
import '../../../onboarding/presentation/widgets/goals_step.dart';
import '../../../onboarding/presentation/widgets/habits_step.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/pin_setup_flow.dart';
import '../widgets/verify_email_step.dart';

enum SetupStep { verify, goals, habits, budget, pin }

/// First run after sign-up: confirm email, three questions, then an optional
/// PIN. Every step can be skipped or left; [AuthViewModel.finishSetup] opens
/// the app. Quitting midway lands in the app on the next launch.
class SetupPage extends StatefulWidget {
  const SetupPage({required this.model, super.key});

  final AuthViewModel model;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final OnboardingViewModel _answers = OnboardingViewModel(
    getIt<ProfileUseCases>(),
    getIt<SettingsUseCases>(),
  );
  var _step = SetupStep.verify;

  @override
  void initState() {
    super.initState();
    getIt<SettingsViewModel>().beginOnboarding();
  }

  @override
  void dispose() {
    _answers.dispose();
    super.dispose();
  }

  void _go(SetupStep step) => setState(() => _step = step);

  /// Questions are over (answered or skipped): record it and go to the PIN.
  void _toPin() {
    unawaited(getIt<SettingsViewModel>().completeOnboarding());
    _go(SetupStep.pin);
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    return switch (_step) {
      SetupStep.verify => VerifyEmailStep(
        model: model,
        onDone: () => _go(SetupStep.goals),
      ),
      SetupStep.goals => GoalsStep(
        model: _answers,
        onNext: () {
          unawaited(_answers.saveGoals());
          _go(SetupStep.habits);
        },
        onSkip: () => _go(SetupStep.habits),
      ),
      SetupStep.habits => HabitsStep(
        model: _answers,
        onNext: () {
          unawaited(_answers.saveHabits());
          _go(SetupStep.budget);
        },
        onSkip: () => _go(SetupStep.budget),
        onBack: () => _go(SetupStep.goals),
      ),
      SetupStep.budget => BudgetStep(
        model: _answers,
        onNext: () {
          unawaited(_answers.saveBudgetDraft());
          _toPin();
        },
        onSkip: _toPin,
        onBack: () => _go(SetupStep.habits),
      ),
      SetupStep.pin => PinSetupFlow(
        model: model,
        onSkip: model.finishSetup,
        onBack: () => _go(SetupStep.budget),
      ),
    };
  }
}
