import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/transaction_row.dart';
import '../../../../core/widgets/transaction_row_text.dart';
import '../../../sync/presentation/widgets/sync_mark_chip.dart';
import '../../domain/transaction.dart';
import 'transaction_naming.dart';

/// One transaction in a list, with its full spoken label.
class TransactionListRow extends StatelessWidget {
  const TransactionListRow({
    required this.row,
    required this.label,
    required this.digits,
    required this.onTap,
    this.showCurrency = false,
    this.highlight,
    this.muted = false,
    this.trailing,
    this.mark,
    this.iconBg,
    super.key,
  });

  final TransactionBundle row;
  final TransactionLabel label;
  final int digits;
  final VoidCallback onTap;

  /// Rows in a currency other than the profile one show its code.
  final bool showCurrency;
  final String? highlight;
  final bool muted;
  final Widget? trailing;

  /// Queued change on this row: the chip is also read to screen readers.
  final SyncMark? mark;

  /// Circle colour override (white while the saved row is marked).
  final Color? iconBg;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final amount = formatMoneyText(label.minor, digits, locale);
    final currency = label.currency == 'VND' ? s.homeSpokenVnd : label.currency;
    final signed = switch (label.tone) {
      MoneyTone.income => s.homeSpokenIncome(amount, currency),
      MoneyTone.expense => s.homeSpokenExpense(amount, currency),
      _ => '$amount $currency',
    };
    return TransactionRow(
      icon: label.icon,
      title: label.title,
      subtitle: label.detail,
      tone: label.tone,
      // Deleted rows: neutral circle, muted glyph and amount.
      muted: muted,
      tags: label.tags,
      highlight: highlight,
      iconBg: iconBg,
      trailing: trailing,
      subtitleWidget: switch (mark) {
        SyncMark.review => TransactionRowNote(
          icon: LucideIcons.triangleAlert,
          text: s.syncChipReview,
          color: context.colors.statusWarning,
          bold: true,
        ),
        SyncMark.waiting => TransactionRowNote(
          icon: LucideIcons.clock,
          text: s.syncChipWaiting,
        ),
        null => null,
      },
      onTap: onTap,
      semanticsLabel: [
        s.homeSpokenRow(signed, label.title, label.detail),
        if (mark != null) SyncMarkChip.label(s, mark!),
      ].join(', '),
      amount: MoneyDisplay(
        minor: label.minor,
        currency: label.currency,
        minorDigits: digits,
        tone: label.tone,
        muted: muted,
        style: FreevaTypography.titleM,
        showCurrency: showCurrency,
      ),
    );
  }
}
