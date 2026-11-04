import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

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
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../debts/presentation/widgets/debt_parts.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../domain/loan.dart';
import '../viewmodels/loan_view_model.dart';

/// "Trả kỳ 25/10" over the loan (LoanPay): amount, principal and interest
/// (editable, prefilled from the next period), wallet. True once saved.
Future<bool?> showLoanPaySheet(
  BuildContext context,
  LoanViewModel model,
  Loan loan,
  LoanScheduleRow? next,
) {
  final s = S.of(context);
  final due = next?.dueDate ?? loan.nextDueDate;
  return showFreevaSheet<bool>(
    context: context,
    titleGap: 0,
    builder: (context) => SheetTitled(
      title: due == null ? s.loanRecordPayment : s.loanPayTitle(debtDay(due)),
      child: _PaySheet(model: model, loan: loan, next: next),
    ),
  );
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.model, required this.loan, this.next});

  final LoanViewModel model;
  final Loan loan;
  final LoanScheduleRow? next;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  final amount = TextEditingController();
  final principal = TextEditingController();
  final interest = TextEditingController();
  late String? walletId = _initialWallet();
  bool saving = false;
  bool inited = false;

  /// Kept while the sheet is open so a resend never pays twice.
  late final String clientId = widget.model.newClientId();

  LoanViewModel get model => widget.model;
  Loan get loan => widget.loan;
  int get digits => model.digitsOf(loan.currencyCode);

  List<Wallet> get _wallets => model.walletsFor(loan.currencyCode);

  String? _initialWallet() {
    final wallets = widget.model.walletsFor(widget.loan.currencyCode);
    final own = wallets.where((w) => w.id == widget.loan.accountId);
    return (own.firstOrNull ?? wallets.firstOrNull)?.id;
  }

  Wallet? get wallet => _wallets.where((w) => w.id == walletId).firstOrNull;

  @override
  void dispose() {
    amount.dispose();
    principal.dispose();
    interest.dispose();
    super.dispose();
  }

  BigInt? _read(TextEditingController c, String locale) => c.text.trim().isEmpty
      ? BigInt.zero
      : parseGroupedMoney(c.text, digits, locale);

  String _fmt(BigInt v, String locale) => formatMoneyText(v, digits, locale);

  void _init(String locale) {
    inited = true;
    final row = widget.next;
    final interestPart = row?.interestMinor ?? loan.periodInterestMinor;
    final principalPart = row?.principalMinor ?? BigInt.zero;
    amount.text = _fmt(interestPart + principalPart, locale);
    principal.text = _fmt(principalPart, locale);
    interest.text = _fmt(interestPart, locale);
  }

  /// A new total keeps this period's interest first; the rest is principal.
  void _amountChanged(String locale) {
    final total = _read(amount, locale) ?? BigInt.zero;
    final owed = widget.next?.interestMinor ?? loan.periodInterestMinor;
    final interestPart = total < owed ? total : owed;
    setState(() {
      interest.text = _fmt(interestPart, locale);
      principal.text = _fmt(total - interestPart, locale);
    });
  }

  /// Editing a part changes the total.
  void _partChanged(String locale) {
    final p = _read(principal, locale) ?? BigInt.zero;
    final i = _read(interest, locale) ?? BigInt.zero;
    setState(() => amount.text = _fmt(p + i, locale));
  }

  Future<void> _pickWallet(S s, bool hidden) async {
    final picked = await showWalletPicker(
      context,
      title: s.loanPayFrom,
      wallets: _wallets,
      selected: walletId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    final p = _read(principal, locale);
    final i = _read(interest, locale);
    final id = walletId;
    if (p == null || i == null || id == null) return;
    setState(() => saving = true);
    final saved = await model.pay(
      loan,
      LoanPayment(
        clientId: clientId,
        principalMinor: p,
        interestMinor: i,
        accountId: id,
        paidOn: model.today,
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
    if (!inited) _init(locale);
    final p = _read(principal, locale);
    final i = _read(interest, locale);
    final tooMuch = p != null && p > loan.outstandingMinor;
    final ready =
        p != null &&
        i != null &&
        p + i > BigInt.zero &&
        !tooMuch &&
        walletId != null &&
        !saving;
    final w = wallet;
    final formatters = [
      MoneyInputFormatter(minorDigits: digits, locale: locale),
    ];
    return BalancesHiddenBuilder(
      builder: (context, hidden) {
        final walletLine = w == null
            ? s.recNeedWallet
            : [
                w.draft.name,
                if (!hidden)
                  s.loanWalletLeft(
                    formatMoneyText(
                      w.balance,
                      model.digitsOf(w.draft.currency),
                      locale,
                    ),
                  ),
                s.txToday.toLowerCase(),
              ].join(' · ');
        return Column(
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
                    symbol: MoneyDisplay.symbolFor(loan.currencyCode),
                    autofocus: false,
                    onChanged: () => _amountChanged(locale),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FormPair(
              first: FreevaTextField(
                label: s.loanPrincipalPart,
                controller: principal,
                keyboardType: TextInputType.number,
                inputFormatters: formatters,
                tabular: true,
                trailingIcon: LucideIcons.penLine,
                onChanged: (_) => _partChanged(locale),
              ),
              second: FreevaTextField(
                label: s.loanInterestPart,
                controller: interest,
                keyboardType: TextInputType.number,
                inputFormatters: formatters,
                tabular: true,
                trailingIcon: LucideIcons.penLine,
                onChanged: (_) => _partChanged(locale),
              ),
            ),
            const SizedBox(height: 18),
            PickerField(
              label: s.loanPayFrom,
              value: walletLine,
              placeholder: w == null,
              leading: FieldIconTile(
                icon: LucideIcons.landmark,
                background: c.tintBlue,
                foreground: c.tintBlueFg,
              ),
              onTap: () => _pickWallet(s, hidden),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                tooMuch ? s.loanTooMuch : s.loanPrincipalHint,
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
        );
      },
    );
  }
}
