import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/overview.dart';

/// One credit card: name + due chip (warning within 7 days), limit bar
/// coloured by level, "Đã dùng … / Hạn mức …".
class CreditCardRow extends StatelessWidget {
  const CreditCardRow({
    required this.card,
    required this.today,
    required this.digits,
    super.key,
  });

  final CreditCardStatus card;
  final DateTime today;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => formatMoneyText(v, digits, locale);
    final due = card.nextDue;
    final soon = card.dueWithin(today, 7);
    final barColor = switch (card.level) {
      CreditLevel.normal => c.data1,
      CreditLevel.high => FreevaPrimitive.amber500,
      CreditLevel.critical => FreevaPrimitive.red500,
    };
    final limit = card.limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                card.wallet.draft.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FreevaTypography.bodyS.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (due != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: soon ? c.statusWarningBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(FreevaRadius.full),
                ),
                child: Text(
                  s.homeCreditDue(DateFormat('dd/MM', locale).format(due)),
                  maxLines: 1,
                  style: FreevaTypography.label.copyWith(
                    color: soon ? c.statusWarning : c.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: FreevaSpace.s2),
        FreevaProgressBar(value: card.ratio, color: barColor),
        const SizedBox(height: FreevaSpace.s2),
        Text(
          limit == null
              ? s.homeCreditUsedNoLimit(money(card.used))
              : s.homeCreditUsed(money(card.used), money(limit)),
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
