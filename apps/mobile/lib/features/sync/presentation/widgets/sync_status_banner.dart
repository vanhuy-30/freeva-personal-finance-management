import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
      final String text;
      if (attention > 0 && waiting > 0) {
        text = s.syncBannerBoth(attention, waiting);
      } else if (attention > 0) {
        text = s.syncBannerAttention(attention);
      } else if (waiting > 0) {
        text = s.syncBannerWaiting(waiting);
      } else if (model.duplicateHint) {
        text = s.syncBannerDuplicate;
      } else {
        return const SizedBox.shrink();
      }
      final warn = attention > 0 || model.schemaMismatch;
      return Padding(
        padding: const EdgeInsets.only(bottom: FreevaSpace.s3),
        child: Semantics(
          button: true,
          liveRegion: true,
          label: text,
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
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        warn ? LucideIcons.triangleAlert : LucideIcons.clock,
                        size: FreevaSize.iconInline,
                        color: warn ? c.statusWarning : c.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          style: FreevaTypography.bodyS.copyWith(
                            fontWeight: FontWeight.w500,
                            color: warn ? c.statusWarning : c.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: warn ? c.statusWarning : c.textSecondary,
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
