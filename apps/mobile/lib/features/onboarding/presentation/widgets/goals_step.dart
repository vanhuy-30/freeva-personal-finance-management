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

/// Question 1 (board ObGoals3): what Freeva should help with, as many as the
/// person likes (server `onboarding.maxGoals`).
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
    OnboardingGoal.budget => s.onbGoalBudget,
    OnboardingGoal.save => s.onbGoalSave,
    OnboardingGoal.debt => s.onbGoalDebt,
    OnboardingGoal.assets => s.onbGoalAssets,
    OnboardingGoal.habits => s.onbGoalHabits,
  };

  static IconData icon(OnboardingGoal goal) => switch (goal) {
    OnboardingGoal.track => LucideIcons.arrowUpDown,
    OnboardingGoal.budget => LucideIcons.chartPie,
    OnboardingGoal.save => LucideIcons.piggyBank,
    OnboardingGoal.debt => LucideIcons.creditCard,
    OnboardingGoal.assets => LucideIcons.trendingUp,
    OnboardingGoal.habits => LucideIcons.calendarCheck,
  };

  /// Icon box fill and glyph as on the board. Picked cards put the glyph on
  /// a white box.
  static (Color, Color) tint(FreevaColors c, OnboardingGoal goal) =>
      switch (goal) {
        OnboardingGoal.track => (c.tintBlue, c.tintBlueFg),
        OnboardingGoal.budget => (c.statusWarningBg, c.statusWarning),
        OnboardingGoal.save => (c.tintGreen, c.tintGreenFg),
        OnboardingGoal.debt => (c.statusDangerBg, c.statusDanger),
        OnboardingGoal.assets => (c.tintCyan, c.tintCyanFg),
        OnboardingGoal.habits => (c.tintViolet, c.tintVioletFg),
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
            s.onbGoalsIntro,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 20),
          Text(
            s.onbGoalsMulti,
            style: FreevaTypography.bodyS.copyWith(
              height: 18 / 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final (i, goal) in OnboardingGoal.values.indexed) ...[
            if (i > 0) const SizedBox(height: FreevaSpace.s2),
            _GoalCard(
              title: label(s, goal),
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

/// Board card: 16 radius, 10/14 padding, 56 min height, 36 icon box r10,
/// one 15 line, 22 check at the end (filled when picked).
class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final (Color, Color) tint;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = BorderRadius.circular(FreevaRadius.md);
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? c.bgSurface : tint.$1,
                    borderRadius: BorderRadius.circular(FreevaRadius.xs),
                  ),
                  child: Icon(icon, size: 18, color: tint.$2),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Text(
                    title,
                    style: FreevaTypography.body.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: FreevaSpace.s3),
                _Check(selected: selected),
              ],
            ),
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

class _Check extends StatelessWidget {
  const _Check({required this.selected});

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
