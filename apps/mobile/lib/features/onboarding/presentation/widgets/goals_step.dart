import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
    OnboardingGoal.track => LucideIcons.receiptText,
    OnboardingGoal.save => LucideIcons.piggyBank,
    OnboardingGoal.budget => LucideIcons.walletMinimal,
    OnboardingGoal.debt => LucideIcons.creditCard,
    OnboardingGoal.emergency => LucideIcons.shield,
    OnboardingGoal.understand => LucideIcons.chartNoAxesColumn,
  };

  /// Unselected icon box (fill, glyph). The board shows track and save only
  /// selected; they take blue and violet from the same tint set.
  static (Color, Color) tint(FreevaColors c, OnboardingGoal goal) =>
      switch (goal) {
        OnboardingGoal.track => (c.tintBlue, c.tintBlueFg),
        OnboardingGoal.save => (c.tintViolet, c.tintVioletFg),
        OnboardingGoal.budget => (c.tintCyan, c.tintCyanFg),
        OnboardingGoal.debt => (c.bgSubtle, c.textPrimary),
        OnboardingGoal.emergency => (c.tintGreen, c.tintGreenFg),
        OnboardingGoal.understand => (c.tintViolet, c.tintVioletFg),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    const goals = OnboardingGoal.values;
    // The 120 tile fits an icon and two lines of label. With large text on
    // a narrow screen it would not, so the goals become full-width rows
    // that grow with their text.
    final tiles =
        MediaQuery.textScalerOf(context).scale(1) <= 1.15 &&
        MediaQuery.sizeOf(context).width >= 360;
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
          if (tiles)
            for (var i = 0; i < goals.length; i += 2) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  for (var j = i; j < i + 2; j++) ...[
                    if (j > i) const SizedBox(width: 10),
                    Expanded(
                      child: SelectableCard.tile(
                        label: label(s, goals[j]),
                        icon: icon(goals[j]),
                        iconBg: tint(c, goals[j]).$1,
                        iconColor: tint(c, goals[j]).$2,
                        disabledOpacity: .55,
                        selected: model.goals.contains(goals[j]),
                        enabled: model.canPickGoal(goals[j]),
                        onTap: () => model.toggleGoal(goals[j]),
                      ),
                    ),
                  ],
                ],
              ),
            ]
          else
            for (final (i, goal) in goals.indexed) ...[
              if (i > 0) const SizedBox(height: FreevaSpace.s2),
              SelectableCard(
                label: label(s, goal),
                icon: icon(goal),
                iconBoxSize: 32,
                iconSize: 17,
                iconBg: tint(c, goal).$1,
                iconColor: tint(c, goal).$2,
                disabledOpacity: .55,
                radius: FreevaRadius.mlg,
                minHeight: 58,
                selected: model.goals.contains(goal),
                enabled: model.canPickGoal(goal),
                onTap: () => model.toggleGoal(goal),
              ),
            ],
        ],
      ),
    );
  }
}
