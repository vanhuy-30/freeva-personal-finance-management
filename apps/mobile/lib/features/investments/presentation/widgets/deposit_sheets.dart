import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
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
import '../../domain/investment.dart';
import '../viewmodels/investment_view_model.dart';
import 'investment_wallet_list.dart';
import '../../../server_config/domain/app_limits.dart';
import '../../../../core/di/injection.dart';

/// "Rút tiền gửi" (board P.12): the money that comes back (starts at
/// principal plus interest, editable), the day and the wallet. A withdrawal
/// always takes the whole deposit. True once saved.
Future<bool?> showDepositWithdrawSheet(
  BuildContext context,
  InvestmentViewModel model,
  Investment deposit,
) {
  final s = S.of(context);
  return showFreevaSheet<bool>(
    context: context,
    title: s.depositWithdraw,
    builder: (context) => _WithdrawSheet(model: model, deposit: deposit),
  );
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet({required this.model, required this.deposit});

  final InvestmentViewModel model;
  final Investment deposit;

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final amount = TextEditingController();
  late String? walletId = _wallets.firstOrNull?.id;
  late String on = widget.model.today;
  bool saving = false;
  bool primed = false;

  /// Kept while the sheet is open so a resend never records it twice.
  late final String clientId = widget.model.newClientId();

  InvestmentViewModel get model => widget.model;
  Investment get deposit => widget.deposit;
  int get digits => model.digitsOf(deposit.currencyCode);
  List get _wallets => [
    for (final w in model.wallets)
      if (w.draft.currency == deposit.currencyCode) w,
  ];

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, digits, locale);

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: on,
      today: model.today,
    );
    if (picked != null) setState(() => on = picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await model.withdraw(
      deposit,
      amountMinor: _value(locale)!,
      accountId: walletId!,
      tradedOn: on,
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
    if (!primed) {
      primed = true;
      amount.text = formatMoneyText(deposit.currentValueMinor, digits, locale);
    }
    final value = _value(locale);
    final ok =
        !saving && walletId != null && value != null && value > BigInt.zero;
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
            FreevaTextField(
              label: s.depositReceive,
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                MoneyInputFormatter(minorDigits: digits, locale: locale),
              ],
              tabular: true,
              suffix: MoneyDisplay.symbolFor(deposit.currencyCode),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            PickerField(
              chevron: false,
              label: s.depositWithdrawDate,
              value: netWorthDate(on, locale, year: true),
              leading: FieldIconTile(
                icon: Icons.calendar_today_outlined,
                background: c.bgSubtle,
                foreground: c.textOnWash,
              ),
              onTap: _pickDate,
            ),
            SectionHeader(s.depositToWallet),
            InvestmentWalletList(
              wallets: [for (final w in _wallets) w],
              selected: walletId,
              digitsOf: model.digitsOf,
              hidden: hidden,
              allowExisting: false,
              onChanged: (id) => setState(() => walletId = id),
            ),
            const SizedBox(height: 16),
            FreevaButton(
              label: value == null
                  ? s.depositWithdraw
                  : s.depositWithdrawButton(
                      '${formatMoneyText(value, digits, locale)} ${MoneyDisplay.symbolFor(deposit.currencyCode)}',
                    ),
              size: FreevaButtonSize.l,
              expand: true,
              loading: saving,
              onPressed: ok ? () => _save(locale) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sửa khoản gửi": name, maturity date and note. True once saved.
Future<bool?> showDepositEditSheet(
  BuildContext context,
  InvestmentViewModel model,
  Investment deposit,
) {
  final s = S.of(context);
  return showFreevaSheet<bool>(
    context: context,
    title: s.depositEditTitle,
    builder: (context) => _EditSheet(model: model, deposit: deposit),
  );
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.model, required this.deposit});

  final InvestmentViewModel model;
  final Investment deposit;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final name = TextEditingController(text: widget.deposit.name);
  late final note = TextEditingController(text: widget.deposit.note ?? '');
  late String? maturity = widget.deposit.maturityDate;
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: maturity ?? widget.model.today,
      today: widget.model.today,
    );
    if (picked != null) setState(() => maturity = picked);
  }

  bool get _valid =>
      !saving &&
      name.text.trim().isNotEmpty &&
      maturity != null &&
      maturity!.compareTo(widget.deposit.startDate ?? '') > 0;

  Future<void> _save() async {
    final s = S.of(context);
    setState(() => saving = true);
    final text = note.text.trim();
    final ok = await widget.model.update(
      widget.deposit,
      name: name.text,
      note: text.isEmpty ? null : text,
      maturityDate: maturity,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    final failure = widget.model.failure;
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
            label: s.investmentName,
            controller: name,
            maxLength:
                getIt<AppLimitsSource>().requireLimits.investmentNameMaxLength,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          PickerField(
            chevron: false,
            label: s.investmentMaturity,
            value: maturity == null
                ? s.investmentPickDate
                : netWorthDate(maturity!, locale, year: true),
            placeholder: maturity == null,
            leading: FieldIconTile(
              icon: Icons.calendar_today_outlined,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          FreevaTextField(
            label: s.investmentNote,
            controller: note,
            maxLength: getIt<AppLimitsSource>().requireLimits.noteMaxLength,
          ),
          const SizedBox(height: 20),
          FreevaButton(
            label: s.depositEditSave,
            size: FreevaButtonSize.l,
            expand: true,
            loading: saving,
            onPressed: _valid ? _save : null,
          ),
        ],
      ),
    );
  }
}
