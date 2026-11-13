import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../budgets/domain/budget_use_cases.dart';
import '../../../goals/domain/goal_use_cases.dart';
import '../../../goals/presentation/widgets/goal_look.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../onboarding/domain/pending_goal_use_cases.dart';
import '../../../onboarding/presentation/viewmodels/onboarding_view_model.dart';
import '../../../onboarding/presentation/viewmodels/setup_wallets_view_model.dart';
import '../../../onboarding/presentation/widgets/budget_suggest_step.dart';
import '../../../onboarding/presentation/widgets/goals_step.dart';
import '../../../onboarding/presentation/widgets/income_step.dart';
import '../../../onboarding/presentation/widgets/saving_step.dart';
import '../../../onboarding/presentation/widgets/setup_wallets_step.dart';
import '../../../profile/domain/profile_use_cases.dart';
import '../../../settings/domain/settings_use_cases.dart';
import '../../../settings/presentation/viewmodels/settings_view_model.dart';
import '../../../wallets/domain/wallet_use_cases.dart';
import '../viewmodels/auth_view_model.dart';
import '../widgets/pin_setup_flow.dart';
import '../widgets/verify_email_step.dart';

enum SetupStep { verify, goals, income, saving, budget, wallets, pin }

/// First run after sign-up: confirm email, three questions (goals, income,
/// saving goal), a budget suggestion when there is income, where the money
/// is (wallets), then an optional PIN. Every step can be skipped or left;
/// [AuthViewModel.finishSetup] opens the app. Quitting midway lands in the
/// app on the next launch. The saving goal is created once a wallet exists.
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
  late final SetupWalletsViewModel _wallets;
  late final PendingGoalUseCases _pending;
  var _step = SetupStep.verify;

  @override
  void initState() {
    super.initState();
    _pending = getIt<PendingGoalUseCases>();
    _answers = OnboardingViewModel(
      getIt<ProfileUseCases>(),
      getIt<SettingsUseCases>(),
      getIt<GoalUseCases>(),
      _pending,
      getIt.isRegistered<BudgetUseCases>() ? getIt<BudgetUseCases>() : null,
      limits: getIt<AppLimitsSource>(),
      today: widget.today,
    );
    unawaited(_answers.load());
    _wallets = SetupWalletsViewModel(getIt<WalletUseCases>());
    getIt<SettingsViewModel>().beginOnboarding();
  }

  @override
  void dispose() {
    _answers.dispose();
    _wallets.dispose();
    super.dispose();
  }

  void _go(SetupStep step) => setState(() => _step = step);

  /// Questions and wallets are over (answered or skipped): record it and go
  /// to the PIN.
  void _toPin() {
    unawaited(getIt<SettingsViewModel>().completeOnboarding());
    // The saving goal needs a wallet; one may exist now.
    unawaited(_pending.flush());
    _go(SetupStep.pin);
  }

  /// After question 3: the budget suggestion when there is one, else wallets.
  void _afterSaving() =>
      _go(_answers.suggestion == null ? SetupStep.wallets : SetupStep.budget);

  @override
  Widget build(BuildContext context) {
    final model = widget.model;
    // The question screens have no back button on the boards; the system
    // back goes to the previous question instead of leaving setup.
    final previous = switch (_step) {
      SetupStep.income => SetupStep.goals,
      SetupStep.saving => SetupStep.income,
      SetupStep.budget => SetupStep.saving,
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
        onNext: () async {
          // Waited for: the saving preview reads the stated income.
          await _answers.saveIncome();
          if (mounted) _go(SetupStep.saving);
        },
        onSkip: () {
          _answers.clearIncome();
          _go(SetupStep.saving);
        },
      ),
      SetupStep.saving => SavingStep(
        model: _answers,
        onNext: () async {
          if (!_answers.savingReady) {
            _answers.clearSaving();
            _afterSaving();
            return;
          }
          final name = goalKindLabel(S.of(context), _answers.savingKind!);
          unawaited(_answers.keepSavingGoal(name));
          await _answers.settlePreview();
          if (mounted) _afterSaving();
        },
        onSkip: () {
          _answers.clearSaving();
          _afterSaving();
        },
      ),
      SetupStep.budget => BudgetSuggestStep(
        suggestion: _answers.suggestion!,
        digits: _answers.digits,
        currency: _answers.currency,
        goalName: _answers.savingKind == null
            ? null
            : goalKindLabel(S.of(context), _answers.savingKind!),
        onUse: () {
          unawaited(_answers.useSuggestion());
          _go(SetupStep.wallets);
        },
        onSkip: () => _go(SetupStep.wallets),
        savingsSharePercent: _answers.savingsSharePercent,
      ),
      SetupStep.wallets => SetupWalletsStep(model: _wallets, onDone: _toPin),
      SetupStep.pin => PinSetupFlow(
        model: model,
        onSkip: model.finishSetup,
        onBack: () => _go(SetupStep.wallets),
      ),
    };
  }
}
