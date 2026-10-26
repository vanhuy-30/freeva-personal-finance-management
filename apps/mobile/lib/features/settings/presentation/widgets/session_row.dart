import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.bgSubtle,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
            ),
            child: ExcludeSemantics(
              child: Icon(
                session.current ? LucideIcons.smartphone : LucideIcons.monitor,
                size: FreevaSize.iconInline,
                color: c.textPrimary,
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
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  s.meSessionDates(
                    started,
                    day.format(session.expiresAt.toLocal()),
                  ),
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w400,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: FreevaSpace.s2),
          if (session.current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: c.statusSuccessBg,
                borderRadius: BorderRadius.circular(FreevaRadius.full),
              ),
              child: Text(
                s.meSessionInUse,
                style: FreevaTypography.label.copyWith(color: c.statusSuccess),
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
                variant: FreevaButtonVariant.secondary,
                size: FreevaButtonSize.xs,
                onPressed: onRevoke,
              ),
            ),
        ],
      ),
    );
  }
}
