import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../forecast/presentation/widgets/forecast_labels.dart';
import '../../domain/net_worth_history.dart';
import 'net_worth_labels.dart';

/// Caption, big number and the change over the window. While a point is
/// touched the caption is its date and the number is its value.
class NetWorthSummary extends StatelessWidget {
  const NetWorthSummary({
    required this.series,
    required this.shown,
    required this.latest,
    required this.currency,
    required this.digits,
    required this.hidden,
    super.key,
  });

  final NetWorthSeries series;
  final NetWorthPoint shown;

  /// Whether [shown] is the latest point (nothing touched).
  final bool latest;
  final String currency;
  final int digits;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final date = netWorthDate(shown.asOf, locale, year: !latest);
    final change = series.changeMinor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          latest ? s.netWorthToday(date) : s.netWorthDate(date),
          style: FreevaTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: MoneyDisplay(
            minor: shown.netWorthMinor,
            currency: currency,
            minorDigits: digits,
            style: FreevaTypography.moneyDisplayCompact.copyWith(
              letterSpacing: -0.9,
            ),
            hidden: hidden,
          ),
        ),
        if (change != null) ...[
          const SizedBox(height: 6),
          Text(
            s.netWorthChange(
              hidden ? '••••••' : signedMoney(change, digits, locale),
              series.window.name,
            ),
            style: FreevaTypography.bodyS.copyWith(
              color: change.isNegative ? c.textSecondary : c.moneyIncome,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}
