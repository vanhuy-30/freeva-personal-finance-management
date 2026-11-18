import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../auth/domain/auth_repository.dart';

/// One signed-in device: its model and system, when it was last used, and
/// "Đang dùng" for this phone or "Đăng xuất" for the others. Sessions from
/// before the server knew devices show "Thiết bị không rõ" (or "Máy này").
class SessionRow extends StatelessWidget {
  const SessionRow({
    required this.session,
    required this.onRevoke,
    this.now,
    super.key,
  });

  final AuthSession session;
  final VoidCallback onRevoke;

  /// Clock for "3 giờ trước"; tests pass a fixed one.
  final DateTime? now;

  static String? _system(AuthSession session) {
    final os = switch (session.platform) {
      'ios' => 'iOS',
      'android' => 'Android',
      _ => null,
    };
    if (os == null) return null;
    final version = session.osVersion;
    return version == null ? os : '$os $version';
  }

  String _when(S s, String started) {
    final used = session.lastUsedAt;
    if (session.current || used == null) return s.meSessionSince(started);
    final ago = (now ?? DateTime.now()).difference(used);
    if (ago.inHours < 1) return s.meSessionActiveNow;
    if (ago.inHours < 24) return s.meSessionActiveHours(ago.inHours);
    return s.meSessionActiveDays(ago.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final day = DateFormat(s.reportShortDatePattern, s.localeName);
    final started = day.format(session.createdAt.toLocal());
    final title =
        session.deviceName ??
        (session.current ? s.meSessionThis : s.meSessionUnknown);
    final system = _system(session);
    // No null-aware collection elements: build_runner's analyzer rejects them.
    final sub = [if (system != null) system, _when(s, started)].join(' · ');
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
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: session.current
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
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
              label: s.meRevokeSemantics(title),
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
