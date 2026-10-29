import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/freeva_card.dart';
import '../../../domain/credit_card_status.dart';

/// "Đến hạn thanh toán 25/10 [còn 4 ngày]", "Ngày chốt sao kê", and minimum
/// payment. The chip shows only when the due date is 7 days away or less.
class CreditInfoCard extends StatelessWidget {
  const CreditInfoCard({
    required this.card,
    required this.today,
    required this.minorDigits,
    super.key,
  });

  final CreditCardStatus card;
  final DateTime today;
  final int minorDigits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final due = card.nextDue;
    final days = card.daysUntilDue(today);
    final closeDay = card.wallet.draft.closeDay;
    final minimum = card.wallet.draft.minimumPayment;
    String money(BigInt value) => formatMoneyText(value, minorDigits, locale);
    final value = FreevaTypography.body.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget row(String label, List<Widget> trailing) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: FreevaTypography.body.copyWith(
                fontSize: 14,
                color: c.textSecondary,
              ),
            ),
          ),
          ...trailing,
        ],
      ),
    );
    return FreevaCard(
      list: true,
      padding: const EdgeInsets.symmetric(horizontal: FreevaSpace.s4),
      child: Column(
        children: [
          row(s.creditDueTitle, [
            Text(
              due == null
                  ? s.creditNotSet
                  : DateFormat('dd/MM', locale).format(due),
              style: value,
            ),
            if (days != null && card.dueWithin(today, 7)) ...[
              const SizedBox(width: FreevaSpace.s2),
              Container(
                height: 24,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: c.statusWarningBg,
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: Text(
                  s.creditDaysLeft(days),
                  maxLines: 1,
                  style: FreevaTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.statusWarning,
                  ),
                ),
              ),
            ],
          ]),
          Divider(height: 1, color: c.listDivider),
          row(s.creditCloseTitle, [
            Text(
              closeDay == null ? s.creditNotSet : s.creditCloseValue(closeDay),
              style: value,
            ),
          ]),
          Divider(height: 1, color: c.listDivider),
          row(s.creditMinimumTitle, [
            Text(
              minimum == null ? s.creditNotSet : money(minimum),
              style: value,
            ),
          ]),
        ],
      ),
    );
  }
}
