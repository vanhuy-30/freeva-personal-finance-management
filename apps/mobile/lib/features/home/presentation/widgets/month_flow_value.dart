import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/balance_card.dart';
import '../../../../core/widgets/money_display.dart';
import '../../domain/overview.dart';

/// Month income or expense on the balance card. A zero (start of a month)
/// is unsigned and uses the muted on-wash colour (B5).
class MonthFlowValue extends StatelessWidget {
  const MonthFlowValue({
    required this.minor,
    required this.tone,
    required this.currency,
    required this.minorDigits,
    super.key,
  });

  final BigInt minor;
  final MoneyTone tone;
  final String currency;
  final int minorDigits;

  @override
  Widget build(BuildContext context) {
    final zero = minor == BigInt.zero;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: MoneyDisplay(
        minor: minor,
        currency: currency,
        minorDigits: minorDigits,
        tone: zero ? MoneyTone.plain : tone,
        style: zero
            ? WashStatTile.valueStyle.copyWith(
                color: context.colors.balanceCardFg,
              )
            : WashStatTile.valueStyle,
        showCurrency: false,
      ),
    );
  }
}

/// "Thu tháng 10" and "Chi tháng 10" tiles under the balance.
class MonthFlowRow extends StatelessWidget {
  const MonthFlowRow({
    required this.flow,
    required this.monthLabel,
    required this.currency,
    required this.minorDigits,
    super.key,
  });

  final MonthFlow flow;
  final String monthLabel;
  final String currency;
  final int minorDigits;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    Widget tile(String label, BigInt minor, MoneyTone tone) => Expanded(
      child: WashStatTile(
        label: label,
        value: MonthFlowValue(
          minor: minor,
          tone: tone,
          currency: currency,
          minorDigits: minorDigits,
        ),
      ),
    );
    return Row(
      children: [
        tile(s.homeIncomeMonth(monthLabel), flow.income, MoneyTone.income),
        const SizedBox(width: FreevaSpace.s2),
        tile(s.homeExpenseMonth(monthLabel), flow.expense, MoneyTone.expense),
      ],
    );
  }
}
