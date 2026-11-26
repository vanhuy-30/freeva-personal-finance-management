import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/progress_bar.dart';
import '../../domain/investment.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import 'investment_labels.dart';

/// One deposit on the Tiền gửi category screen (board PKindDepositA): name,
/// term and rate, the amount, a term progress bar, the maturity day and the
/// expected interest. Opens its detail (P.11).
class InvestmentDepositTile extends StatelessWidget {
  const InvestmentDepositTile({
    required this.deposit,
    required this.digits,
    required this.hidden,
    required this.today,
    required this.onTap,
    super.key,
  });

  final Investment deposit;
  final int digits;
  final bool hidden;

  /// Today as yyyy-MM-dd.
  final String today;
  final VoidCallback onTap;

  /// Whole months of the term, null without both dates or under a month.
  int? get _months {
    final start = deposit.startDate;
    final end = deposit.maturityDate;
    if (start == null || end == null) return null;
    final months = (depositTermDays(start, end) / 30.4375).round();
    return months < 1 ? null : months;
  }

  /// Share of the term already gone, 0–1.
  double get _elapsed {
    final start = deposit.startDate;
    final end = deposit.maturityDate;
    if (start == null || end == null) return 0;
    final total = depositTermDays(start, end);
    if (total <= 0) return 1;
    return (depositTermDays(start, today) / total).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final bps = deposit.interestRateBps;
    final symbol = MoneyDisplay.symbolFor(deposit.currencyCode);
    String money(BigInt v) =>
        hidden ? '••••••' : '${formatMoneyText(v, digits, locale)} $symbol';
    final value = money(deposit.costBasisMinor);
    final interest = deposit.interestAtMaturity;
    final end = deposit.maturityDate;
    final matured = deposit.maturedOn(today);
    final months = _months;
    final sub = [
      if (months != null) s.depositTermMonths(months),
      if (bps != null) '${depositRateText(bps, locale)}%',
    ].join(' · ');
    final small = FreevaTypography.label.copyWith(
      fontWeight: FontWeight.w400,
      color: c.textSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final left = end == null || matured
        ? null
        : depositTermDays(today, end).clamp(0, 1 << 30);
    return FreevaCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      semanticsLabel: '${deposit.name}, $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.statusSuccessBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      LucideIcons.landmark,
                      size: 22,
                      color: c.moneyIncome,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FreevaTypography.titleM.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(sub, style: small),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: FreevaTypography.titleM.copyWith(
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (end != null) ...[
              const SizedBox(height: 12),
              FreevaProgressBar(
                value: matured ? 1 : _elapsed,
                color: matured ? c.statusWarning : c.moneyIncome,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: matured
                        ? Text(
                            s.depositWithdraw,
                            style: FreevaTypography.bodyS.copyWith(
                              fontWeight: FontWeight.w600,
                              color: c.actionPrimary,
                            ),
                          )
                        : Text(s.depositDaysLeft(left ?? 0), style: small),
                  ),
                  Text(
                    s.depositMaturesOn(netWorthDate(end, locale, year: true)),
                    style: small,
                  ),
                ],
              ),
            ],
            if (interest != null && interest > BigInt.zero) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.statusSuccessBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(s.depositInterest, style: small)),
                      Text(
                        hidden
                            ? '••••••'
                            : '+${formatMoneyText(interest, digits, locale)} $symbol',
                        style: FreevaTypography.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.moneyIncome,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
