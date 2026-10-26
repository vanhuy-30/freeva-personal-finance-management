import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/sync_item.dart';
import 'sync_item_view.dart';
import 'sync_labels.dart';

/// One queued change: category icon, name, "Thêm · lý do hoặc giờ", amount,
/// and "Thử lại" / "Bỏ" for what needs the person or × for what only waits.
class SyncItemRow extends StatelessWidget {
  const SyncItemRow({
    required this.item,
    required this.view,
    required this.detail,
    this.onView,
    this.onRetry,
    this.onDiscard,
    this.compactAction = false,
    super.key,
  });

  final SyncQueueItem item;
  final SyncItemView view;

  /// Second line after the action: the reason, or the time.
  final String detail;

  /// "Xem": opens the comparison of a conflict.
  final VoidCallback? onView;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  /// Waiting rows use a × instead of a text button.
  final bool compactAction;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final line = s.syncItemLine(syncActionLabel(s, item.action), detail);
    final minor = view.minor;
    // Narrow screen or large text: the amount sits under the name instead
    // of squeezing it.
    final stacked =
        context.isCompactScreen ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final amount = minor == null
        ? null
        : MoneyDisplay(
            minor: minor,
            currency: view.currency,
            minorDigits: view.minorDigits,
            tone: view.tone,
            style: FreevaTypography.titleM,
            showCurrency: false,
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FreevaSpace.s3),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.bgSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(view.icon, size: 20, color: c.textPrimary),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.title,
                  style: FreevaTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: FreevaTypography.bodyS.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                if (stacked && amount != null)
                  Padding(
                    padding: const EdgeInsets.only(top: FreevaSpace.s1),
                    child: amount,
                  ),
                if (!compactAction &&
                    (onView != null || onRetry != null || onDiscard != null))
                  Padding(
                    padding: const EdgeInsets.only(top: FreevaSpace.s1),
                    child: Wrap(
                      children: [
                        if (onView != null)
                          TextButton(
                            onPressed: onView,
                            child: Text(s.syncViewAction),
                          ),
                        if (onRetry != null)
                          TextButton(
                            onPressed: onRetry,
                            child: Text(s.syncRetry),
                          ),
                        if (onDiscard != null)
                          TextButton(
                            onPressed: onDiscard,
                            style: TextButton.styleFrom(
                              foregroundColor: c.textSecondary,
                            ),
                            child: Text(s.syncDiscardConfirm),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (amount != null && !stacked) ...[
            const SizedBox(width: FreevaSpace.s2),
            amount,
          ],
          if (compactAction && onDiscard != null)
            IconButton(
              tooltip: s.syncDiscardSemantics(view.title),
              onPressed: onDiscard,
              icon: Icon(
                LucideIcons.x,
                size: FreevaSize.iconInline,
                color: c.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
