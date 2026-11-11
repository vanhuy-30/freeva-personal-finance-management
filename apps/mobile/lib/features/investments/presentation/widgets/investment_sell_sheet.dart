import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/money/quantity.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/settings_group.dart';
import '../../../auth/presentation/widgets/auth_message.dart';
import '../../../net_worth/presentation/widgets/net_worth_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import 'investment_labels.dart';
import 'investment_wallet_list.dart';

/// "Bán Vàng SJC" (board P.9). True once the sale is saved. The sell price
/// starts at the current price and becomes the new current price.
Future<bool?> showInvestmentSellSheet(
  BuildContext context,
  InvestmentViewModel model,
  Investment investment,
) {
  final s = S.of(context);
  return showFreevaSheet<bool>(
    context: context,
    title: s.investmentSellTitle(investment.name),
    builder: (context) => _SellSheet(model: model, investment: investment),
  );
}

class _SellSheet extends StatefulWidget {
  const _SellSheet({required this.model, required this.investment});

  final InvestmentViewModel model;
  final Investment investment;

  @override
  State<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<_SellSheet> {
  final quantity = TextEditingController();
  final price = TextEditingController();
  late String? walletId = _wallets.firstOrNull?.id;
  late String soldOn = widget.model.today;
  bool saving = false;
  bool primed = false;

  /// Kept while the sheet is open so a resend never records the sale twice.
  late final String clientId = widget.model.newClientId();

  InvestmentViewModel get model => widget.model;
  Investment get inv => widget.investment;
  int get digits => model.digitsOf(inv.currencyCode);
  BigInt get held => parseQuantityApi(inv.quantity) ?? BigInt.zero;
  List get _wallets => [
    for (final w in model.wallets)
      if (w.draft.currency == inv.currencyCode) w,
  ];

  @override
  void dispose() {
    quantity.dispose();
    price.dispose();
    super.dispose();
  }

  BigInt? _qty(String locale) =>
      parseGroupedMoney(quantity.text, quantityDigits, locale);

  BigInt? _price(String locale) =>
      parseGroupedMoney(price.text, digits, locale);

  bool _valid(String locale) {
    final q = _qty(locale);
    final p = _price(locale);
    return !saving &&
        walletId != null &&
        q != null &&
        q > BigInt.zero &&
        q <= held &&
        p != null &&
        p > BigInt.zero;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: soldOn,
      today: model.today,
    );
    if (picked != null) setState(() => soldOn = picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await model.sell(
      inv,
      SellDraft(
        clientId: clientId,
        quantity: _qty(locale)!,
        priceMinor: _price(locale)!,
        accountId: walletId!,
        tradedOn: soldOn,
      ),
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
    if (!primed) {
      primed = true;
      final current = inv.latestPriceMinor;
      if (current != null) {
        price.text = formatMoneyText(current, digits, locale);
      }
    }
    final q = _qty(locale);
    final p = _price(locale);
    final total = q == null || p == null ? null : quantityTotalMinor(q, p);
    final realized = total == null || q == null || q > held
        ? null
        : total - soldCostMinor(inv.costBasisMinor, held, q);
    final unit = inv.unit;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Padding(
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
            Text(
              s.investmentHeld(investmentQuantityText(s, held, unit, locale)),
              textAlign: TextAlign.center,
              style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: c.tintBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.investmentReceive,
                      style: FreevaTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  MoneyDisplay(
                    minor: total ?? BigInt.zero,
                    currency: inv.currencyCode,
                    minorDigits: digits,
                    style: FreevaTypography.titleM,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FormPair(
              first: FreevaTextField(
                label: s.investmentSellQty,
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  MoneyInputFormatter(
                    minorDigits: quantityDigits,
                    locale: locale,
                  ),
                ],
                tabular: true,
                suffix: s.investmentUnit(unit),
                onChanged: (_) => setState(() {}),
              ),
              second: FreevaTextField(
                label: s.investmentSellPrice(unit),
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  MoneyInputFormatter(minorDigits: digits, locale: locale),
                ],
                tabular: true,
                suffix: MoneyDisplay.symbolFor(inv.currencyCode),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(
                  () => quantity.text = formatQuantity(held, locale),
                ),
                child: Text(
                  s.investmentSellAll(
                    investmentQuantityText(s, held, unit, locale),
                  ),
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: c.textLink,
                  ),
                ),
              ),
            ),
            PickerField(
              chevron: false,
              label: s.investmentSellDate,
              value: netWorthDate(soldOn, locale, year: true),
              leading: FieldIconTile(
                icon: Icons.calendar_today_outlined,
                background: c.bgSubtle,
                foreground: c.textOnWash,
              ),
              onTap: _pickDate,
            ),
            SectionHeader(s.investmentToWallet),
            InvestmentWalletList(
              wallets: [for (final w in _wallets) w],
              selected: walletId,
              digitsOf: model.digitsOf,
              hidden: hidden,
              allowExisting: false,
              onChanged: (id) => setState(() => walletId = id),
            ),
            const SizedBox(height: 14),
            if (realized != null && !hidden)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  s.investmentRealized(
                    investmentSigned(realized, digits, locale),
                  ),
                  textAlign: TextAlign.center,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: realized.isNegative ? c.moneyExpense : c.moneyIncome,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            FreevaButton(
              label: q == null || total == null || q <= BigInt.zero || q > held
                  ? s.investmentSell
                  : s.investmentSellButton(
                      investmentQuantityText(s, q, unit, locale),
                      '${formatMoneyText(total, digits, locale)} ${MoneyDisplay.symbolFor(inv.currencyCode)}',
                    ),
              size: FreevaButtonSize.l,
              expand: true,
              loading: saving,
              onPressed: _valid(locale) ? () => _save(locale) : null,
            ),
          ],
        ),
      ),
    );
  }
}
