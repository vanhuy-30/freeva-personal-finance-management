import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/transaction_row_text.dart';

/// What a transaction row says about its queued change.
enum SyncMark {
  /// Conflict or error: the person has to look.
  review,

  /// Only waiting for the network.
  waiting,
}

/// Second line of a list row with a queued change: "⚠ Cần xem lại" in the
/// warning colour, or "🕒 Chờ đồng bộ" in the secondary colour. Takes the
/// place of "category · wallet".
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
    final text = label(S.of(context), mark);
    return switch (mark) {
      SyncMark.review => TransactionRowNote(
        icon: LucideIcons.triangleAlert,
        text: text,
        color: c.statusWarning,
        bold: true,
      ),
      SyncMark.waiting => TransactionRowNote(
        icon: LucideIcons.clock,
        text: text,
        color: c.textSecondary,
      ),
    };
  }
}
