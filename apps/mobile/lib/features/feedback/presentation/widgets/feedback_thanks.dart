import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import 'paper_plane_illustration.dart';

/// After sending: a paper plane, "Cảm ơn bạn!", one line and "Xong" at the
/// bottom.
class FeedbackThanks extends StatelessWidget {
  const FeedbackThanks({
    required this.replies,
    required this.onDone,
    super.key,
  });

  /// The user asked to be answered by email.
  final bool replies;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(FreevaSpace.s6, 0, FreevaSpace.s6, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 120),
                  const PaperPlaneIllustration(),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(
                      s.fbThanks,
                      textAlign: TextAlign.center,
                      style: FreevaTypography.headline.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: FreevaSpace.s2),
                  Text(
                    replies ? s.fbThanksReply : s.fbThanksNoReply,
                    textAlign: TextAlign.center,
                    style: FreevaTypography.body.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FreevaButton(
            label: s.fbDone,
            variant: FreevaButtonVariant.ink,
            size: FreevaButtonSize.l,
            expand: true,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
