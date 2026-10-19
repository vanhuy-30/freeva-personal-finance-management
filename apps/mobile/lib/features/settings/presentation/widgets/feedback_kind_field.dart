import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/app_preferences.dart';

class FeedbackKindField extends StatelessWidget {
  const FeedbackKindField({
    required this.kind,
    required this.onChanged,
    super.key,
  });

  final FeedbackKind kind;
  final ValueChanged<FeedbackKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return RadioGroup<FeedbackKind>(
      groupValue: kind,
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      child: Column(
        children: [
          RadioListTile<FeedbackKind>(
            title: Text(s.feedbackIdea),
            value: FeedbackKind.idea,
          ),
          RadioListTile<FeedbackKind>(
            title: Text(s.feedbackProblem),
            value: FeedbackKind.problem,
          ),
        ],
      ),
    );
  }
}
