import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/personal_debt.dart';
import 'debt_parts.dart';

/// One person in the Người quen list: letter avatar, name, "Cho mượn 12/10 ·
/// hạn 30/10", what is still owed and the due tag.
class DebtRow extends StatelessWidget {
  const DebtRow({
    required this.debt,
    required this.digits,
    required this.today,
    required this.onTap,
    super.key,
  });

  final PersonalDebt debt;
  final int digits;
  final String today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final day = debtDay(debt.occurredOn);
    final due = debt.dueDate;
    final subtitle = [
      debt.lent ? s.debtLentOn(day) : s.debtBorrowedOn(day),
      if (!debt.settled) due == null ? s.debtNoDue : s.debtDueOn(debtDay(due)),
    ].join(' · ');
    final tag = debt.settled ? null : dueTag(context, today, due);
    final amount = formatMoneyText(
      debt.settled ? debt.principalMinor : debt.outstandingMinor,
      digits,
      locale,
    );
    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                NameAvatar(name: debt.counterparty),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.counterparty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      style: FreevaTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: debt.settled ? c.textSecondary : c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (tag != null) ...[const SizedBox(height: 4), tag],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
