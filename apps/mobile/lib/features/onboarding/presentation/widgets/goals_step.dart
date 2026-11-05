import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/check_mark.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../domain/onboarding_answers.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 1 (board ObGoals3): what Freeva should help with, at most two.
/// With two picked the third does not take a tap (the board draws it plain).
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
  };

  static String sub(S s, OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.track => s.onbGoalTrackSub,
    OnboardingGoal.save => s.onbGoalSaveSub,
    OnboardingGoal.budget => s.onbGoalBudgetSub,
  };

  static IconData icon(OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.track => LucideIcons.list,
    OnboardingGoal.save => LucideIcons.piggyBank,
    OnboardingGoal.budget => LucideIcons.chartPie,
  };

  /// Icon box fill and glyph: blue, green and yellow on the board. Picked
  /// cards put the glyph on a white box.
  static (Color, Color) tint(FreevaColors c, OnboardingGoal goal) =>
      switch (goal) {
        OnboardingGoal.track => (c.tintBlue, c.tintBlueFg),
        OnboardingGoal.save => (c.tintGreen, c.tintGreenFg),
        OnboardingGoal.budget => (c.statusWarningBg, c.statusWarning),
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
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
          for (final (i, goal) in OnboardingGoal.values.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            _GoalCard(
              title: label(s, goal),
              sub: sub(s, goal),
              icon: icon(goal),
              tint: tint(c, goal),
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

/// Board card: 20 radius, 16 padding, 40 icon box r12, 16/600 title over a
/// 13 line, 22 radio at the end (filled with a check when picked).
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.sub,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String sub;
  final IconData icon;
  final (Color, Color) tint;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.lg);
    Widget card = AnimatedContainer(
      duration: FreevaMotion.fast,
      decoration: BoxDecoration(
        color: selected ? c.tintBlue : c.bgSurface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? c.actionPrimary : c.borderDefault,
          width: selected ? FreevaBorder.selected : FreevaBorder.defaultValue,
        ),
      ),
      child: InkWell(
        borderRadius: radius,
        splashFactory: NoSplash.splashFactory,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(FreevaSpace.s4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? c.bgSurface : tint.$1,
                  borderRadius: BorderRadius.circular(FreevaRadius.sm),
                ),
                child: Icon(icon, size: 20, color: tint.$2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FreevaTypography.body.copyWith(
                        fontSize: 16,
                        height: 19 / 16,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: FreevaTypography.bodyS.copyWith(
                        height: 16 / 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      checked: selected,
      enabled: enabled,
      child: PressScale(enabled: enabled, child: card),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: FreevaMotion.fast,
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.actionPrimary : null,
        border: selected
            ? null
            : Border.all(color: c.borderStrong, width: FreevaBorder.selected),
      ),
      child: selected
          ? CheckMark(size: 12, strokeWidth: 3.5, color: c.textOnAction)
          : null,
    );
  }
}
