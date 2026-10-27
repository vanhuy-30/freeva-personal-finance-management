import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../viewmodels/sync_view_model.dart';
import 'sync_labels.dart';

/// Top card of Đồng bộ: sending, update needed, no connection, couldn't
/// send, or waiting. Says what is happening and that nothing is lost. The
/// all-done state is [SyncDoneView], not a card.
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({required this.model, required this.now, super.key});

  final SyncViewModel model;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final stamp = model.lastSyncedAt;
    final last = stamp == null
        ? s.syncLastNever
        : syncLast(s, stamp, now, locale);
    if (model.schemaMismatch) {
      return _Tile(
        icon: LucideIcons.arrowDownToLine,
        iconBg: c.bgSurface,
        iconFg: c.statusWarning,
        textColor: c.statusWarning,
        background: c.statusWarningBg,
        title: s.syncUpdateTitle,
        subtitle: s.syncUpdateBody,
      );
    }
    if (model.syncing) {
      return _Tile(
        icon: LucideIcons.rotateCw,
        iconBg: c.tintBlue,
        iconFg: c.tintBlueFg,
        title: s.syncSending(model.waiting.length),
        subtitle: s.syncSendingSub,
        progress: true,
      );
    }
    final retry = FreevaButton(
      label: s.syncRetry,
      size: FreevaButtonSize.xs,
      onPressed: model.flush,
    );
    if (model.link == SyncLink.offline) {
      return _Tile(
        icon: LucideIcons.cloudOff,
        iconBg: c.statusInfoBg,
        iconFg: c.statusInfo,
        title: s.syncOffline,
        subtitle: last,
        action: retry,
      );
    }
    if (model.link == SyncLink.unavailable) {
      return _Tile(
        icon: LucideIcons.cloudAlert,
        iconBg: c.statusWarningBg,
        iconFg: c.statusWarning,
        title: s.syncUnavailable,
        subtitle: s.syncUnavailableSub,
        action: retry,
      );
    }
    if (model.items.isNotEmpty) {
      return _Tile(
        icon: LucideIcons.clock,
        title: s.syncWaitingCard,
        subtitle: last,
        action: retry,
      );
    }
    return _Tile(
      icon: LucideIcons.cloudCheck,
      iconBg: c.statusSuccessBg,
      iconFg: c.statusSuccess,
      title: s.syncAllDone,
      subtitle: last,
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconBg,
    this.iconFg,
    this.textColor,
    this.background,
    this.action,
    this.progress = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconBg;
  final Color? iconFg;

  /// Title and subtitle colour; null keeps primary / secondary.
  final Color? textColor;

  /// Tinted card without shadow (update needed); null is the white card.
  final Color? background;
  final Widget? action;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // On a narrow screen or at a large text size the button drops under the
    // text instead of squeezing it.
    final stacked =
        context.isCompactScreen ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: FreevaSpace.s4,
          vertical: background == null ? FreevaSpace.s4 : 18,
        ),
        decoration: BoxDecoration(
          color: background ?? c.cardBg,
          borderRadius: BorderRadius.circular(FreevaComponent.cardRadius),
          boxShadow: background == null ? FreevaElevation.s1 : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg ?? c.bgSubtle,
                    borderRadius: BorderRadius.circular(FreevaRadius.smd),
                  ),
                  child: Icon(icon, size: 22, color: iconFg ?? c.textPrimary),
                ),
                const SizedBox(width: FreevaSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: FreevaTypography.titleM.copyWith(
                          color: textColor ?? c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: FreevaTypography.bodyS.copyWith(
                          color: textColor ?? c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action != null && !stacked) ...[
                  const SizedBox(width: FreevaSpace.s2),
                  action!,
                ],
              ],
            ),
            if (action != null && stacked) ...[
              const SizedBox(height: FreevaSpace.s3),
              Align(alignment: Alignment.centerRight, child: action),
            ],
            if (progress) ...[
              const SizedBox(height: FreevaSpace.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(FreevaRadius.full),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  color: c.data1,
                  backgroundColor: c.borderDivider,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
