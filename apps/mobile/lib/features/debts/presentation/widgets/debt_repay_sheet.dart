import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/personal_debt.dart';
import '../viewmodels/debt_view_model.dart';
import 'debt_parts.dart';

/// "Tuấn trả bạn" / "Bạn trả Chị Lan" over the debt (DebtPay). True once a
/// repayment is saved.
Future<bool?> showDebtRepaySheet(
  BuildContext context,
  DebtViewModel model,
  PersonalDebt debt,
) {
  final s = S.of(context);
  return showFreevaSheet<bool>(
    context: context,
    titleGap: 0,
    builder: (context) => SheetTitled(
      title: debt.lent
          ? s.debtPayTheyTitle(debt.counterparty)
          : s.debtPayYouTitle(debt.counterparty),
      child: _RepaySheet(model: model, debt: debt),
    ),
  );
}

class _RepaySheet extends StatefulWidget {
  const _RepaySheet({required this.model, required this.debt});

  final DebtViewModel model;
  final PersonalDebt debt;

  @override
  State<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends State<_RepaySheet> {
  final amount = TextEditingController();
  late String? walletId = _initialWallet();
  late String paidOn = widget.model.today;
  bool saving = false;

  /// Kept while the sheet is open so a resend never records it twice.
  late final String clientId = widget.model.newClientId();

  DebtViewModel get model => widget.model;
  PersonalDebt get debt => widget.debt;
  int get digits => model.digitsOf(debt.currencyCode);

  List<Wallet> get _wallets => model.walletsFor(debt.currencyCode);

  String? _initialWallet() {
    final wallets = widget.model.walletsFor(widget.debt.currencyCode);
    final own = wallets.where((w) => w.id == widget.debt.accountId);
    return (own.firstOrNull ?? wallets.firstOrNull)?.id;
  }

  Wallet? get wallet => _wallets.where((w) => w.id == walletId).firstOrNull;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, digits, locale);

  void _fill(BigInt value, String locale) =>
      setState(() => amount.text = formatMoneyText(value, digits, locale));

  Future<void> _pickWallet(S s, bool hidden) async {
    final picked = await showWalletPicker(
      context,
      title: debt.lent ? s.debtToWallet : s.debtFromWalletShort,
      wallets: _wallets,
      selected: walletId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: paidOn,
      today: model.today,
    );
    if (picked != null) setState(() => paidOn = picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    final value = _value(locale);
    final id = walletId;
    if (value == null || id == null) return;
    setState(() => saving = true);
    final saved = await model.repay(
      debt,
      DebtRepay(
        clientId: clientId,
        amountMinor: value,
        accountId: id,
        paidOn: paidOn,
      ),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (saved != null) {
      Navigator.of(context).pop(true);
      return;
    }
    showFreevaToast(
      context,
      message: model.failure?.code == AuthError.conflict
          ? s.meConflict
          : s.meSaveError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final value = _value(locale);
    final tooMuch = value != null && value > debt.outstandingMinor;
    final ready =
        value != null &&
        value > BigInt.zero &&
        !tooMuch &&
        walletId != null &&
        !saving;
    final w = wallet;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Column(
              children: [
                Text(
                  s.debtAmount,
                  style: FreevaTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w500,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SheetAmountField(
                  controller: amount,
                  digits: digits,
                  locale: locale,
                  symbol: MoneyDisplay.symbolFor(debt.currencyCode),
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: FreevaSpace.s2,
            runSpacing: FreevaSpace.s2,
            children: [
              FreevaChip(
                label: s.debtHalf,
                selected: false,
                onTap: () =>
                    _fill(halfOf(debt.outstandingMinor, digits), locale),
              ),
              FreevaChip(
                label: s.debtAll(
                  formatMoneyText(debt.outstandingMinor, digits, locale),
                ),
                selected: false,
                onTap: () => _fill(debt.outstandingMinor, locale),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FormPair(
            first: PickerField(
              chevron: false,
              label: debt.lent ? s.debtToWallet : s.debtFromWalletShort,
              value: w?.draft.name ?? s.recNeedWallet,
              placeholder: w == null,
              leading: w == null
                  ? FieldIconTile(
                      icon: LucideIcons.wallet,
                      background: c.tintCyan,
                      foreground: c.tintCyanFg,
                    )
                  : WalletTypeIcon(type: w.draft.type, size: 32),
              onTap: () => _pickWallet(s, hidden),
            ),
            second: PickerField(
              chevron: false,
              label: s.debtDate,
              value: paidOn == model.today ? s.txToday : debtDay(paidOn),
              leading: FieldIconTile(
                icon: LucideIcons.calendar,
                background: c.bgSubtle,
                foreground: c.textOnWash,
              ),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              tooMuch
                  ? s.debtTooMuch
                  : debt.lent
                  ? s.debtSettleHintLent
                  : s.debtSettleHintBorrowed,
              style: FreevaTypography.bodyS.copyWith(
                height: 18 / 13,
                color: tooMuch ? c.statusDanger : c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          FreevaButton(
            label: s.debtSave,
            size: FreevaButtonSize.l,
            expand: true,
            loading: saving,
            onPressed: ready ? () => _save(locale) : null,
          ),
        ],
      ),
    );
  }
}
