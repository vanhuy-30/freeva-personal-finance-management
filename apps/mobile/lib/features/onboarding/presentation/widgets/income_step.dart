import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../profile/presentation/widgets/income_band_list.dart';
import '../viewmodels/onboarding_view_model.dart';
import 'onboarding_frame.dart';

/// Question 2 (board ObIncome): monthly income as a band, or "Không muốn
/// chia sẻ". A privacy line sits above the buttons.
class IncomeStep extends StatelessWidget {
  const IncomeStep({
    required this.model,
    required this.onNext,
    required this.onSkip,
    super.key,
  });

  final OnboardingViewModel model;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => OnboardingFrame(
        step: 2,
        title: s.onbIncomeTitle,
        skipLabel: s.authLaterLink,
        onSkip: onSkip,
        onNext: onNext,
        pinnedGap: FreevaSpace.s4,
        pinned: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(LucideIcons.lock, size: 16, color: c.textSecondary),
              ),
              const SizedBox(width: FreevaSpace.s2),
              Expanded(
                child: Text(
                  s.onbIncomePrivacy,
                  style: FreevaTypography.bodyS.copyWith(
                    height: 18 / 13,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          const SizedBox(height: FreevaSpace.s2),
          Text(
            s.onbIncomeSub,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FreevaSpace.s6),
          IncomeBandList(
            bands: model.incomeBands,
            digits: model.digits,
            selected: model.income,
            notShared: model.incomeNotShared,
            onBand: model.pickIncome,
            onNotShared: model.pickNotShared,
          ),
        ],
      ),
    );
  }
}
