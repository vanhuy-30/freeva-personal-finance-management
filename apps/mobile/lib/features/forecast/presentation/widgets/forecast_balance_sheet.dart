import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/sheet_amount_field.dart';

/// Result of the sheet: [reset] goes back to the wallet total, otherwise
/// [minor] is the amount the user typed.
class ForecastBalanceChoice {
  const ForecastBalanceChoice.amount(BigInt this.minor) : reset = false;
  const ForecastBalanceChoice.reset() : minor = null, reset = true;

  final BigInt? minor;
  final bool reset;
}

/// "Số dư bắt đầu": the user types the balance the forecast starts from.
Future<ForecastBalanceChoice?> showForecastBalanceSheet(
  BuildContext context, {
  required BigInt current,
  required String currency,
  required int digits,
  required bool custom,
}) => showFreevaSheet<ForecastBalanceChoice>(
  context: context,
  title: S.of(context).forecastBalanceTitle,
  builder: (context) => _BalanceSheet(
    current: current,
    currency: currency,
    digits: digits,
    custom: custom,
  ),
);

class _BalanceSheet extends StatefulWidget {
  const _BalanceSheet({
    required this.current,
    required this.currency,
    required this.digits,
    required this.custom,
  });

  final BigInt current;
  final String currency;
  final int digits;
  final bool custom;

  @override
  State<_BalanceSheet> createState() => _BalanceSheetState();
}

class _BalanceSheetState extends State<_BalanceSheet> {
  final controller = TextEditingController();
  bool inited = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(controller.text, widget.digits, locale);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    if (!inited) {
      inited = true;
      if (!widget.current.isNegative) {
        controller.text = formatMoneyText(
          widget.current,
          widget.digits,
          locale,
        );
      }
    }
    final value = _value(locale);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.forecastBalanceHint,
          textAlign: TextAlign.center,
          style: FreevaTypography.bodyS.copyWith(
            height: 1.21,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: SheetAmountField(
            controller: controller,
            digits: widget.digits,
            locale: locale,
            symbol: MoneyDisplay.symbolFor(widget.currency),
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 20),
        FreevaButton(
          label: s.forecastBalanceApply,
          size: FreevaButtonSize.l,
          expand: true,
          onPressed: value == null
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(ForecastBalanceChoice.amount(value)),
        ),
        if (widget.custom) ...[
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: () =>
                  Navigator.of(context)
                      .pop(const ForecastBalanceChoice.reset()),
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  s.forecastBalanceReset,
                  textAlign: TextAlign.center,
                  style: FreevaTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.actionPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
