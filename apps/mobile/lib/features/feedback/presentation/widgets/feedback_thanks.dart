import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';

/// After sending: a paper plane, "Cảm ơn bạn!", one line and "Xong".
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
      padding: EdgeInsets.all(context.screenMargin),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: c.tintBlue,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Icon(LucideIcons.send, size: 40, color: c.tintBlueFg),
              ),
            ),
          ),
          const SizedBox(height: FreevaSpace.s5),
          Semantics(
            header: true,
            child: Text(
              s.fbThanks,
              textAlign: TextAlign.center,
              style: FreevaTypography.headline.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: FreevaSpace.s2),
          Text(
            replies ? s.fbThanksReply : s.fbThanksNoReply,
            textAlign: TextAlign.center,
            style: FreevaTypography.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: FreevaSpace.s8),
          FreevaButton(
            label: s.fbDone,
            variant: FreevaButtonVariant.ink,
            expand: true,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}
