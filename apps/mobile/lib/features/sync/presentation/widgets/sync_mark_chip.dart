import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';

/// What a transaction row says about its queued change.
enum SyncMark {
  /// Conflict or error: the person has to look.
  review,

  /// Only waiting for the network.
  waiting,
}

/// "Cần xem lại" (warning chip) or the "Chờ đồng bộ" clock, on a list row.
class SyncMarkChip extends StatelessWidget {
  const SyncMarkChip({required this.mark, super.key});

  final SyncMark mark;

  static String label(S s, SyncMark mark) => switch (mark) {
    SyncMark.review => s.syncChipReview,
    SyncMark.waiting => s.syncChipWaiting,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = S.of(context);
    final text = label(s, mark);
    return switch (mark) {
      SyncMark.review => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.statusWarningBg,
          borderRadius: BorderRadius.circular(FreevaRadius.full),
        ),
        child: Text(
          text,
          style: FreevaTypography.bodyS.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: c.statusWarning,
          ),
        ),
      ),
      SyncMark.waiting => Icon(
        LucideIcons.clock,
        size: 16,
        color: c.textSecondary,
        semanticLabel: text,
      ),
    };
  }
}
