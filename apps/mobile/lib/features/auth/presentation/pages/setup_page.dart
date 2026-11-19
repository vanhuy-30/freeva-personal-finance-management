import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../goals/presentation/widgets/goal_look.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../onboarding/domain/pending_goal_use_cases.dart';
import '../../../onboarding/presentation/viewmodels/onboarding_view_model.dart';
import '../../../onboarding/presentation/widgets/done_step.dart';
import '../../../onboarding/presentation/widgets/goals_step.dart';
import '../../../onboarding/presentation/widgets/income_step.dart';
import '../../../onboarding/presentation/widgets/saving_step.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/verify_email_step.dart';

enum SetupStep { verify, goals, income, saving, done }

/// First run after sign-up: confirm email, three questions (goals, income
/// band, saving goal), then Hoàn tất. Every step can be skipped or left;
/// "Khám phá Freeva" calls [AuthViewModel.finishSetup] and opens the app,
/// where wallets, the PIN and the monthly budget are set up. Quitting midway
/// lands in the app on the next launch. The saving goal is created once a
/// wallet exists.
class SetupPage extends StatefulWidget {
  const SetupPage({required this.model, this.today, super.key});

  final AuthViewModel model;

  /// Fixed date for goldens; null = device date.
  final DateTime? today;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  // Built in initState, not lazily: dispose must never reach getIt (it may
  // already be reset when the tree is torn down).
  late final OnboardingViewModel _answers;
  var _step = SetupStep.verify;

  @override
  void initState() {
    super.initState();
    _answers = OnboardingViewModel(
      getIt<ProfileUseCases>(),
      getIt<PendingGoalUseCases>(),
      limits: getIt<AppLimitsSource>(),
      today: widget.today,
    );
    unawaited(_answers.load());
    getIt<SettingsViewModel>().beginOnboarding();
  }

  @override
  void dispose() {
    _answers.dispose();
    super.dispose();
  }

  void _go(SetupStep step) => setState(() => _step = step);

  /// The questions are over (answered or skipped): record it and show
  /// Hoàn tất.
  void _toDone() {
    unawaited(getIt<SettingsViewModel>().completeOnboarding());
    _go(SetupStep.done);
  }

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    // The question screens have no back button on the boards; the system
    // back goes to the previous question instead of leaving setup.
    final previous = switch (_step) {
      SetupStep.income => SetupStep.goals,
      SetupStep.saving => SetupStep.income,
      _ => null,
    };
    return PopScope(
      canPop: previous == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && previous != null) _go(previous);
      },
      child: _stepView(model),
    );
  }

  Widget _stepView(AuthViewModel model) {
    return switch (_step) {
      SetupStep.verify => VerifyEmailStep(
        model: model,
        onDone: () => _go(SetupStep.goals),
      ),
      SetupStep.goals => GoalsStep(
        model: _answers,
        onNext: () {
          unawaited(_answers.saveGoals());
          _go(SetupStep.income);
        },
        onSkip: () => _go(SetupStep.income),
      ),
      SetupStep.income => IncomeStep(
        model: _answers,
        onNext: () {
          unawaited(_answers.saveIncome());
          _go(SetupStep.saving);
        },
        onSkip: () {
          _answers.clearIncome();
          _go(SetupStep.saving);
        },
      ),
      SetupStep.saving => SavingStep(
        model: _answers,
        onNext: () {
          if (_answers.savingReady) {
            final label = goalKindLabel(S.of(context), _answers.savingKind!);
            unawaited(_answers.keepSavingGoal(label));
          } else {
            _answers.clearSaving();
          }
          _toDone();
        },
        onSkip: () {
          _answers.clearSaving();
          _toDone();
        },
      ),
      SetupStep.done => DoneStep(onStart: model.finishSetup),
    };
  }
}
