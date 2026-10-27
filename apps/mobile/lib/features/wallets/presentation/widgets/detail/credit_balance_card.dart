import 'package:flutter/material.dart';

import '../../../../../core/l10n/generated/app_localizations.dart';
import '../../../../../core/money/money_text.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.g.dart';
import '../../../../../core/widgets/balance_card.dart';
import '../../../../../core/widgets/money_display.dart';
import '../../../../../core/widgets/progress_bar.dart';
import '../../../domain/credit_card_status.dart';
import '../credit_level_color.dart';

/// Wash card of a credit card: debt, limit bar, "Còn dùng được … · Hạn mức".
class CreditBalanceCard extends StatelessWidget {
  const CreditBalanceCard({
    required this.card,
    required this.minorDigits,
    required this.hidden,
    super.key,
  });

  final CreditCardStatus card;
  final int minorDigits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final currency = card.wallet.draft.currency;
    final limit = card.limit;
    final available = card.available;
    final text = FreevaTypography.bodyS.copyWith(
      color: c.textOnWash,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    String money(BigInt v) => formatMoneyText(v, minorDigits, locale);
    return WashSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.creditDebtLabel,
            style: text.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: FreevaSpace.s2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyDisplay(
              minor: card.used,
              currency: currency,
              minorDigits: minorDigits,
              style: context.isCompactScreen
                  ? FreevaTypography.moneyDisplayCompact
                  : FreevaTypography.moneyDisplay,
              currencyColor: c.textOnWash,
              hidden: hidden,
            ),
          ),
          if (limit != null && available != null) ...[
            const SizedBox(height: 14),
            // On the wash: white track, primary bar until the warning levels.
            FreevaProgressBar(
              value: card.ratio,
              color: card.level == CreditLevel.normal
                  ? c.actionPrimary
                  : creditLevelColor(context, card.level),
              trackColor: c.bgSurface.withValues(alpha: .8),
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: FreevaSpace.s3,
              runSpacing: FreevaSpace.s1,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${s.creditAvailableLabel} '),
                      TextSpan(
                        text: hidden ? '••••••' : money(available),
                        style: text.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  style: text,
                ),
                Text(s.creditLimit(money(limit)), style: text),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
