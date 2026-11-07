import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';

/// "Giá Vàng SJC" (board P.10): the manual price of one unit and the day it
/// was quoted. True once saved.
Future<bool?> showInvestmentPriceSheet(
  BuildContext context,
  InvestmentViewModel model,
  Investment investment,
) {
  final s = S.of(context);
  return showFreevaSheet<bool>(
    context: context,
    title: s.investmentPriceTitle(investment.name),
    builder: (context) => _PriceSheet(model: model, investment: investment),
  );
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.model, required this.investment});

  final InvestmentViewModel model;
  final Investment investment;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  final price = TextEditingController();
  late String quotedOn = widget.model.today;
  bool saving = false;

  /// Kept while the sheet is open so a resend never records the price twice.
  late final String clientId = widget.model.newClientId();

  InvestmentViewModel get model => widget.model;
  Investment get inv => widget.investment;
  int get digits => model.digitsOf(inv.currencyCode);

  @override
  void dispose() {
    price.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(price.text, digits, locale);

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: quotedOn,
      today: model.today,
    );
    if (picked != null) setState(() => quotedOn = picked);
  }

  /// Today counts as now; another day as midday, so it is never in the
  /// future.
  DateTime get _quotedAt {
    final y = int.parse(quotedOn.substring(0, 4));
    final m = int.parse(quotedOn.substring(5, 7));
    final d = int.parse(quotedOn.substring(8, 10));
    return quotedOn == model.today ? DateTime.now() : DateTime(y, m, d, 12);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await model.setPrice(
      inv,
      _value(locale)!,
      _quotedAt,
      clientId: clientId,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    final failure = model.failure;
    showFreevaToast(
      context,
      message: failure == null ? s.meSaveError : authFailureText(s, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final previous = inv.latestPriceMinor;
    final at = inv.latestPriceAt?.toLocal();
    final value = _value(locale);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FreevaTextField(
            label: s.investmentPriceOne(inv.unit),
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              MoneyInputFormatter(minorDigits: digits, locale: locale),
            ],
            tabular: true,
            suffix: MoneyDisplay.symbolFor(inv.currencyCode),
            onChanged: (_) => setState(() {}),
          ),
          if (previous != null && at != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                s.investmentPricePrev(
                  formatMoneyText(previous, digits, locale),
                  netWorthDate(
                    '${at.year}-${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}',
                    locale,
                  ),
                ),
                style: FreevaTypography.bodyS.copyWith(
                  color: c.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          const SizedBox(height: 14),
          PickerField(
            chevron: false,
            label: s.investmentQuoteDate,
            value: netWorthDate(quotedOn, locale, year: true),
            leading: FieldIconTile(
              icon: Icons.calendar_today_outlined,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),
          FreevaButton(
            label: s.investmentSavePrice,
            size: FreevaButtonSize.l,
            expand: true,
            loading: saving,
            onPressed: !saving && value != null && !value.isNegative
                ? () => _save(locale)
                : null,
          ),
        ],
      ),
    );
  }
}
