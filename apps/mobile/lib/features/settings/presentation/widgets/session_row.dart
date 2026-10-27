import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../auth/domain/auth_repository.dart';

/// One signed-in device: "Máy này" with a chip, or another one with "Thu hồi".
/// The API has no device names, so the row says only which one it is.
class SessionRow extends StatelessWidget {
  const SessionRow({required this.session, required this.onRevoke, super.key});

  final AuthSession session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final day = DateFormat(s.reportShortDatePattern, s.localeName);
    final started = day.format(session.createdAt.toLocal());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: session.current ? c.tintGreen : c.bgSubtle,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                LucideIcons.smartphone,
                size: FreevaSize.iconInline,
                color: session.current ? c.tintGreenFg : c.textOnWash,
              ),
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.current ? s.meSessionThis : s.meSessionOther,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: session.current
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.meSessionDates(
                    started,
                    day.format(session.expiresAt.toLocal()),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          if (session.current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.statusSuccessBg,
                borderRadius: BorderRadius.circular(FreevaRadius.full),
              ),
              child: Text(
                s.meSessionInUse,
                style: FreevaTypography.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.statusSuccess,
                ),
              ),
            )
          else
            Semantics(
              label: s.meRevokeSemantics(started),
              button: true,
              excludeSemantics: true,
              onTap: onRevoke,
              child: FreevaButton(
                label: s.meRevoke,
                variant: FreevaButtonVariant.dangerOutline,
                size: FreevaButtonSize.compact,
                onPressed: onRevoke,
              ),
            ),
        ],
      ),
    );
  }
}
