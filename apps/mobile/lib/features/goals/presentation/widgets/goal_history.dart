import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../domain/goal.dart';

/// "Lịch sử" of a goal: contributions, withdrawals and corrected numbers in
/// one white group, newest first.
class GoalHistory extends StatelessWidget {
  const GoalHistory({required this.entries, required this.digits, super.key});

  final List<GoalEntry> entries;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FreevaCard(
      list: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, entry) in entries.indexed) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.listDivider),
            _Row(entry: entry, digits: digits),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.digits});

  final GoalEntry entry;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat(
      'dd/MM',
      locale,
    ).format(DateTime.parse(entry.occurredOn));
    final amount = entry.amountMinor == null
        ? null
        : formatMoneyText(entry.amountMinor!, digits, locale);
    final (title, sub, icon, fill, ink) = switch (entry.kind) {
      GoalEntryKind.contribute => (
        entry.transfer
            ? s.goalHistoryContributeTransfer
            : s.goalHistoryContribute,
        entry.transfer ? date : s.goalHistoryStays(date),
        LucideIcons.arrowDownToLine,
        c.tintGreen,
        c.tintGreenFg,
      ),
      GoalEntryKind.withdraw => (
        entry.transfer ? s.goalHistoryWithdrawTransfer : s.goalHistoryWithdraw,
        date,
        LucideIcons.arrowUpFromLine,
        c.bgSubtle,
        c.textOnWash,
      ),
      GoalEntryKind.adjust => (
        s.goalHistoryAdjust,
        date,
        LucideIcons.penLine,
        c.bgSubtle,
        c.textOnWash,
      ),
    };
    final amountText = switch (entry.kind) {
      GoalEntryKind.contribute => '+$amount',
      GoalEntryKind.withdraw => '−$amount',
      GoalEntryKind.adjust => '',
    };
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
                child: Icon(icon, size: 17, color: ink),
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
                      fontWeight: FontWeight.w500,
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
                    ),
                  ),
                ],
              ),
            ),
            if (amountText.isNotEmpty)
              Text(
                amountText,
                style: FreevaTypography.titleM.copyWith(
                  color: entry.kind == GoalEntryKind.contribute
                      ? c.moneyIncome
                      : c.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
