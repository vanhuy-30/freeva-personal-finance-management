import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

class OnboardingControls extends StatelessWidget {
  const OnboardingControls({
    required this.step,
    required this.last,
    required this.loading,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final int step;
  final bool last;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        if (step > 0)
          TextButton(
            onPressed: loading ? null : onBack,
            child: Text(s.onboardingBack),
          ),
        const Spacer(),
        FilledButton(
          onPressed: loading ? null : onNext,
          child: Text(last ? s.onboardingFinish : s.onboardingNext),
        ),
      ],
    );
  }
}
