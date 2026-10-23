import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/selectable_card.dart';
import '../../domain/onboarding_answers.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 1: what to improve, at most two. Once two are picked the rest dim.
class GoalsStep extends StatelessWidget {
  const GoalsStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static String label(S s, OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.track => s.onbGoalTrack,
    OnboardingGoal.save => s.onbGoalSave,
    OnboardingGoal.budget => s.onbGoalBudget,
    OnboardingGoal.debt => s.onbGoalDebt,
    OnboardingGoal.emergency => s.onbGoalEmergency,
    OnboardingGoal.understand => s.onbGoalUnderstand,
  };

  static IconData icon(OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.track => LucideIcons.receipt,
    OnboardingGoal.save => LucideIcons.piggyBank,
    OnboardingGoal.budget => LucideIcons.wallet,
    OnboardingGoal.debt => LucideIcons.creditCard,
    OnboardingGoal.emergency => LucideIcons.shieldCheck,
    OnboardingGoal.understand => LucideIcons.chartPie,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    const goals = OnboardingGoal.values;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => OnboardingFrame(
        step: 1,
        title: s.onbGoalsTitle,
        skipLabel: s.authLaterLink,
        onSkip: onSkip,
        onNext: onNext,
        children: [
          const SizedBox(height: FreevaSpace.s2),
          Text(
            s.onbGoalsSub,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FreevaSpace.s6),
          for (var i = 0; i < goals.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + 2; j++) ...[
                    if (j > i) const SizedBox(width: 10),
                    Expanded(
                      child: SelectableCard(
                        label: label(s, goals[j]),
                        icon: icon(goals[j]),
                        selected: model.goals.contains(goals[j]),
                        enabled: model.canPickGoal(goals[j]),
                        onTap: () => model.toggleGoal(goals[j]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
