import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../auth/presentation/widgets/auth_scaffold.dart';
import 'journey_illustration.dart';

/// Hoàn tất (board ObDone): the journey drawing, a title, one line and
/// "Khám phá Freeva" into the app.
class DoneStep extends StatelessWidget {
  const DoneStep({required this.onStart, super.key});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return AuthScaffold(
      topGap: 36,
      footer: FreevaButton(
        label: s.onbDoneStart,
        size: FreevaButtonSize.l,
        expand: true,
        onPressed: onStart,
      ),
      children: [
        // The board draws it 350 wide, a little past the 24 margins.
        const Center(
          child: FittedBox(fit: BoxFit.scaleDown, child: JourneyIllustration()),
        ),
        const SizedBox(height: FreevaSpace.s5),
        AuthTitle(s.onbDoneTitle),
        const SizedBox(height: FreevaSpace.s3),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 330),
            child: Text(
              s.onbDoneSub,
              textAlign: TextAlign.center,
              style: FreevaTypography.body.copyWith(color: c.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
