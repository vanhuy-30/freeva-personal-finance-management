import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/press_scale.dart';
import '../../domain/sync_item.dart';
import 'sync_item_view.dart';
import 'sync_labels.dart';

/// How a queued change is drawn on Đồng bộ.
enum SyncRowStyle {
  /// "Cần bạn xem": amount on the name line, action tag + reason, one pill
  /// button on the right ("Xem", "Thử lại" or "Bỏ").
  review,

  /// "Đang chờ gửi": like [review] with the time and a × on the right.
  waiting,

  /// "Đang giữ trên máy": "Thêm · 09:12", amount on the right.
  holding,

  /// "Đang gửi": "Thêm · −55.000" and a spinner on the right.
  sending,
}

/// One queued change: category icon, name, what changed and why or when,
/// amount, and what the person can do about it.
class SyncItemRow extends StatelessWidget {
  const SyncItemRow({
    required this.item,
    required this.view,
    required this.detail,
    this.style = SyncRowStyle.review,
    this.onView,
    this.onRetry,
    this.onDiscard,
    super.key,
  });

  final SyncQueueItem item;
  final SyncItemView view;

  /// Second line after the action: the reason, or the time.
  final String detail;
  final SyncRowStyle style;

  /// "Xem": opens the comparison of a conflict.
  final VoidCallback? onView;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final removed = item.action == SyncAction.delete;
    final action = syncActionLabel(s, item.action);
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
            muted: removed,
            style: FreevaTypography.titleM,
            showCurrency: false,
          );
    final name = Text(
      view.title,
      style: FreevaTypography.body.copyWith(
        fontWeight: FontWeight.w500,
        color: removed && _tagged ? c.textSecondary : c.textPrimary,
        decoration: removed && _tagged
            ? TextDecoration.lineThrough
            : TextDecoration.none,
        decorationColor: c.textSecondary,
      ),
    );
    final small = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
    );
    final Widget second = switch (style) {
      SyncRowStyle.review || SyncRowStyle.waiting => Semantics(
        container: true,
        label: s.syncItemLine(action, detail),
        excludeSemantics: true,
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.only(right: FreevaSpace.s1),
                  child: _ActionTag(action: item.action, label: action),
                ),
              ),
              TextSpan(text: detail),
            ],
          ),
          style: small,
        ),
      ),
      SyncRowStyle.holding => Text(
        s.syncItemLine(action, detail),
        style: small,
      ),
      SyncRowStyle.sending => Text(
        s.syncItemLine(action, _signed(context)),
        style: small,
      ),
    };
    final amountOnRight =
        style == SyncRowStyle.holding && amount != null && !stacked;
    final amountOnName = _tagged && amount != null && !stacked;
    final amountBelow =
        amount != null && stacked && style != SyncRowStyle.sending;
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
            child: Icon(
              view.icon,
              size: FreevaSize.iconSm,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: FreevaSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (amountOnName)
                  // Amount at the end of the name line; it drops under the
                  // name when both don't fit.
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: FreevaSpace.s2,
                      children: [name, amount],
                    ),
                  )
                else
                  name,
                const SizedBox(height: 2),
                second,
                if (amountBelow)
                  Padding(
                    padding: const EdgeInsets.only(top: FreevaSpace.s1),
                    child: amount,
                  ),
                if (stacked && style == SyncRowStyle.review)
                  Wrap(
                    spacing: FreevaSpace.s2,
                    children: _trailing(
                      s,
                      c,
                      stacked: false,
                    ).whereType<_PillButton>().toList(),
                  ),
              ],
            ),
          ),
          if (amountOnRight) ...[const SizedBox(width: FreevaSpace.s2), amount],
          ..._trailing(s, c, stacked: stacked),
        ],
      ),
    );
  }

  bool get _tagged =>
      style == SyncRowStyle.review || style == SyncRowStyle.waiting;

  String _signed(BuildContext context) {
    final minor = view.minor;
    if (minor == null) return '';
    final locale = Localizations.localeOf(context).toString();
    final sign = switch (view.tone) {
      MoneyTone.income => '+',
      MoneyTone.expense => '−',
      _ => '',
    };
    return '$sign${formatMoneyText(minor, view.minorDigits, locale)}';
  }

  List<Widget> _trailing(S s, FreevaColors c, {required bool stacked}) {
    final discard = onDiscard == null
        ? null
        : IconButton(
            tooltip: s.syncDiscardSemantics(view.title),
            onPressed: onDiscard,
            // 44 touch, not Material's 48: keeps the row near the board's 64.
            style: IconButton.styleFrom(
              minimumSize: const Size.square(FreevaSize.touch),
              fixedSize: const Size.square(FreevaSize.touch),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              LucideIcons.x,
              size: FreevaSize.iconChip,
              color: c.textSecondary,
            ),
          );
    switch (style) {
      case SyncRowStyle.holding:
        return const [];
      case SyncRowStyle.sending:
        return [
          const SizedBox(width: FreevaSpace.s3),
          SizedBox.square(
            dimension: 24,
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  strokeCap: StrokeCap.round,
                  color: c.actionPrimary,
                  backgroundColor: c.borderDivider,
                ),
              ),
            ),
          ),
        ];
      case SyncRowStyle.waiting:
        return [if (discard != null) discard];
      case SyncRowStyle.review:
        // One button, like the board: "Xem" for a conflict, else "Thử lại",
        // else "Bỏ". A retryable row keeps × to drop it.
        final Widget? main = onView != null
            ? _PillButton(label: s.syncViewAction, ink: true, onTap: onView!)
            : onRetry != null
            ? _PillButton(label: s.syncRetry, onTap: onRetry!)
            : onDiscard != null
            ? _PillButton(label: s.syncDiscardConfirm, onTap: onDiscard!)
            : null;
        final extra = onView == null && onRetry != null ? discard : null;
        // Narrow screen or large text: the buttons go under the text.
        if (stacked) return const [];
        return [
          if (main != null) ...[const SizedBox(width: FreevaSpace.s2), main],
          if (extra != null) extra,
        ];
    }
  }
}

/// "Thêm" / "Sửa" / "Xoá" pill before the reason or time.
class _ActionTag extends StatelessWidget {
  const _ActionTag({required this.action, required this.label});

  final SyncAction action;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blueFg = dark ? c.tintBlueFg : c.actionPrimaryPressed;
    final (bg, fg) = switch (action) {
      SyncAction.create => (c.tintGreen, c.tintGreenFg),
      SyncAction.update || SyncAction.restore => (c.tintBlue, blueFg),
      SyncAction.delete => (c.bgSubtle, c.textOnWash),
    };
    return Container(
      // 11/14 text + 3 + 3 = the 20 high board tag.
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(FreevaRadius.full),
      ),
      child: Text(
        label,
        style: FreevaTypography.overline.copyWith(letterSpacing: 0, color: fg),
      ),
    );
  }
}

/// 32 high pill button in a 44 touch area: ink ("Xem") or outlined.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.ink = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool ink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      child: PressScale(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: FreevaSize.touch,
              minWidth: FreevaSize.touch,
            ),
            child: Center(
              widthFactor: 1,
              child: Container(
                // 13/18 text + 7 + 7 = the 32 high board pill.
                padding: const EdgeInsets.symmetric(
                  horizontal: FreevaSpace.s3,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: ink ? c.buttonInkBg : null,
                  border: ink
                      ? null
                      : Border.all(color: c.buttonSecondaryBorder),
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: Text(
                  label,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ink ? c.buttonInkFg : c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
