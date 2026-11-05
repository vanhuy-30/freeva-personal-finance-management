import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../../../installments/domain/card_installment.dart';
import '../../../../recurring/presentation/widgets/rec_tag.dart';

/// "Phải trả kỳ này · 25/11" of a card with installments (board `WCredit3`):
/// amount 20/600, "Còn N ngày" tag, "Gồm … trả góp · tối thiểu …".
class CreditPeriodCard extends StatelessWidget {
  const CreditPeriodCard({
    required this.due,
    required this.today,
    required this.minorDigits,
    this.minimum,
    super.key,
  });

  final CardPeriodDue due;
  final DateTime today;
  final int minorDigits;
  final BigInt? minimum;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, minorDigits, locale);
    final days = DateTime.utc(
      due.dueOn.year,
      due.dueOn.month,
      due.dueOn.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final min = minimum;
    final secondary = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.creditDueThisPeriod(
                          DateFormat('dd/MM', locale).format(due.dueOn),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: secondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        money(due.amountMinor),
                        maxLines: 1,
                        style: FreevaTypography.titleL.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (days >= 0) ...[
                  const SizedBox(width: 8),
                  RecTag(
                    s.creditDaysLeftTag(days),
                    background: c.statusWarningBg,
                    color: c.statusWarning,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            min == null
                ? s.creditIncludesNoMin(money(due.installmentMinor))
                : s.creditIncludes(money(due.installmentMinor), money(min)),
            style: secondary,
          ),
        ],
      ),
    );
  }
}
