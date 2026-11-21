import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_card.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../domain/spending_forecast.dart';
import 'spend_forecast_labels.dart';

/// Money with a real minus: "−1.200.000".
String balanceMoney(BigInt v, int digits, String locale) => v.isNegative
    ? '−${formatMoneyText(v.abs(), digits, locale)}'
    : formatMoneyText(v, digits, locale);

/// "Cuối tháng N còn khoảng": the wallets' money at month end, a range, a
/// warning when it runs out, and what the figure is made of.
class SpendForecastBalance extends StatelessWidget {
  const SpendForecastBalance({
    required this.balance,
    required this.period,
    required this.digits,
    super.key,
  });

  final BalanceOutlook balance;
  final SpendForecastPeriod? period;
  final int digits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    String money(BigInt v) => balanceMoney(v, digits, locale);
    final out = balance.runsOutOn;
    final low = balance.endMinor.isNegative;
    final variable = balance.variableAheadMinor;
    return FreevaCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.spendBalanceHeadline(forecastMonth(s, locale, period)),
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            money(balance.endMinor),
            maxLines: 1,
            style: FreevaTypography.moneyDisplayCompact.copyWith(
              letterSpacing: -0.8,
              color: low ? c.statusDanger : c.textPrimary,
            ),
          ),
          if (balance.paceKnown) ...[
            const SizedBox(height: 4),
            Text(
              s.spendBalanceRange(
                money(balance.endLowMinor),
                money(balance.endHighMinor),
              ),
              style: FreevaTypography.bodyS.copyWith(
                color: c.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (out != null) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.statusDanger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(FreevaRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: FreevaSize.iconSm,
                      color: c.statusDanger,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.spendBalanceRunsOut(netWorthDate(out, locale)),
                        style: FreevaTypography.bodyS.copyWith(
                          fontWeight: FontWeight.w600,
                          color: c.statusDanger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Divider(height: 1, color: c.borderDivider),
          _Line(label: s.spendBalanceNow, value: money(balance.balanceMinor)),
          if (balance.incomeAheadMinor > BigInt.zero)
            _Line(
              label: s.spendBalanceIncome,
              value: '+${money(balance.incomeAheadMinor)}',
              color: c.moneyIncome,
            ),
          if (balance.billsAheadMinor > BigInt.zero)
            _Line(
              label: s.spendBalanceBills,
              value: '−${money(balance.billsAheadMinor)}',
            ),
          if (variable != null)
            _Line(label: s.spendBalanceDaily, value: '−${money(variable)}'),
          const SizedBox(height: 4),
          Text(
            variable == null ? s.spendBalanceNoDaily : s.spendBalanceNote,
            style: FreevaTypography.label.copyWith(
              fontWeight: FontWeight.w400,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: FreevaTypography.bodyM.copyWith(color: c.textSecondary),
            ),
          ),
          Text(
            value,
            style: FreevaTypography.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              color: color ?? c.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
