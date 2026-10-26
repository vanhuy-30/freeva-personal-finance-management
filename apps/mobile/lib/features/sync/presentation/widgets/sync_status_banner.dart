import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../viewmodels/sync_view_model.dart';

/// Strip on top of the transaction list: yellow when something needs the
/// person, neutral when changes only wait for the network, gone when there is
/// nothing. Opens the Đồng bộ screen.
class SyncStatusBanner extends StatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  State<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends State<SyncStatusBanner> {
  late final SyncViewModel model = getIt<SyncViewModel>();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final s = S.of(context);
      final c = context.colors;
      final attention = model.attention.length;
      final waiting = model.waiting.length;
      final String title;
      String? detail;
      if (attention > 0) {
        title = s.syncBannerAttention(attention);
        if (waiting > 0) detail = s.syncBannerOthersWaiting(waiting);
      } else if (waiting > 0) {
        title = s.syncBannerWaiting(waiting);
      } else {
        return const SizedBox.shrink();
      }
      final spoken = attention > 0 && waiting > 0
          ? s.syncBannerBoth(attention, waiting)
          : title;
      final warn = attention > 0 || model.schemaMismatch;
      final fg = warn ? c.statusWarning : c.textPrimary;
      final iconFg = warn ? c.statusWarning : c.textSecondary;
      return Padding(
        padding: const EdgeInsets.only(bottom: FreevaSpace.s4),
        child: Semantics(
          button: true,
          liveRegion: true,
          label: spoken,
          excludeSemantics: true,
          child: Material(
            color: warn ? c.statusWarningBg : c.bgSubtle,
            borderRadius: BorderRadius.circular(FreevaRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(FreevaRadius.md),
              onTap: () => context.push('/sync'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: FreevaSize.touch),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: FreevaSpace.s3,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        warn ? LucideIcons.triangleAlert : LucideIcons.clock,
                        size: FreevaSize.iconInline,
                        color: iconFg,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: FreevaTypography.bodyM.copyWith(
                                fontWeight: FontWeight.w600,
                                color: fg,
                              ),
                            ),
                            if (detail != null)
                              Text(
                                detail,
                                style: FreevaTypography.bodyS.copyWith(
                                  color: fg,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        LucideIcons.chevronRight,
                        size: FreevaSize.iconChip,
                        color: iconFg,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
