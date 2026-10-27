import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/selectable_card.dart';
import '../../domain/onboarding_answers.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 2: how money is managed today, and how often it is reviewed.
class HabitsStep extends StatelessWidget {
  const HabitsStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    required this.onBack,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  static String habitLabel(S s, TrackingHabit habit) => switch (habit) {
    TrackingHabit.manual => s.onbHabitManual,
    TrackingHabit.spreadsheet => s.onbHabitSpreadsheet,
    TrackingHabit.app => s.onbHabitApp,
    TrackingHabit.none => s.onbHabitNone,
  };

  static IconData habitIcon(TrackingHabit habit) => switch (habit) {
    TrackingHabit.manual => LucideIcons.pen,
    TrackingHabit.spreadsheet => LucideIcons.table,
    TrackingHabit.app => LucideIcons.smartphone,
    TrackingHabit.none => LucideIcons.locate,
  };

  static String cadenceLabel(S s, ReviewCadence cadence) => switch (cadence) {
    ReviewCadence.daily => s.onbCadenceDaily,
    ReviewCadence.weekly => s.onbCadenceWeekly,
    ReviewCadence.monthly => s.onbCadenceMonthly,
    ReviewCadence.rarely => s.onbCadenceRarely,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => OnboardingFrame(
        step: 2,
        title: s.onbHabitTitle,
        skipLabel: s.authLaterLink,
        onSkip: onSkip,
        onNext: onNext,
        onBack: onBack,
        children: [
          const SizedBox(height: FreevaSpace.s5),
          for (final habit in TrackingHabit.values) ...[
            SelectableCard(
              label: habitLabel(s, habit),
              icon: habitIcon(habit),
              selected: model.habit == habit,
              onTap: () => model.pickHabit(habit),
              iconBoxSize: 32,
              iconSize: 17,
              radio: true,
              radius: FreevaRadius.mlg,
              minHeight: 58,
            ),
            const SizedBox(height: FreevaSpace.s2),
          ],
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              s.onbCadenceTitle,
              style: FreevaTypography.titleL.copyWith(
                height: 24 / 17,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: FreevaSpace.s3),
          Wrap(
            spacing: FreevaSpace.s2,
            runSpacing: FreevaSpace.s2,
            children: [
              for (final cadence in ReviewCadence.values)
                FreevaChip(
                  size: FreevaChipSize.large,
                  label: cadenceLabel(s, cadence),
                  selected: model.cadence == cadence,
                  onTap: () => model.pickCadence(cadence),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
