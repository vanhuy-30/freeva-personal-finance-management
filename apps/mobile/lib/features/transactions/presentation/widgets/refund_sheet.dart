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
import '../../../recurring/domain/recurring_calendar.dart';
import '../../../recurring/presentation/widgets/recurring_labels.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'composer/date_picker_sheet.dart';
import 'composer/wallet_picker_sheet.dart';
import 'transaction_labels.dart';
import 'transaction_naming.dart';
import '../../../../core/money/currency_catalog.dart';

/// "Hoàn tiền Áo khoác" over the expense (M, màn 3, `TxRefund`). True once
/// a refund is saved. Online only.
Future<bool?> showRefundSheet(
  BuildContext context,
  TransactionViewModel model,
  TransactionBundle expense,
  TransactionNaming naming,
) => showFreevaSheet<bool>(
  context: context,
  titleGap: 0,
  builder: (_) => _RefundSheet(model: model, expense: expense, naming: naming),
);

class _RefundSheet extends StatefulWidget {
  const _RefundSheet({
    required this.model,
    required this.expense,
    required this.naming,
  });

  final TransactionViewModel model;
  final TransactionBundle expense;
  final TransactionNaming naming;

  @override
  State<_RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<_RefundSheet> {
  final amount = TextEditingController();
  late String? walletId = _initialWallet();
  late String on = widget.model.today() ?? widget.expense.occurredOn;
  bool saving = false;

  /// Kept while the sheet is open so a resend never records it twice.
  late final String clientId = widget.model.newClientId();

  TransactionViewModel get model => widget.model;
  TransactionBundle get expense => widget.expense;
  String get currency => expense.legs.first.currencyCode;

  int digitsOf(String code) =>
      model.currencies.where((x) => x.code == code).firstOrNull?.minorDigits ??
      CurrencyCatalog.current.digits(code);

  int get digits => digitsOf(currency);

  /// The API takes only a wallet in the expense's currency.
  List<Wallet> get _wallets => [
    for (final w in model.wallets)
      if (!w.archived && w.draft.currency == currency) w,
  ];

  String? _initialWallet() {
    final own = _wallets.where(
      (w) => w.id == widget.expense.legs.first.accountId,
    );
    return (own.firstOrNull ?? _wallets.firstOrNull)?.id;
  }

  Wallet? get wallet => _wallets.where((w) => w.id == walletId).firstOrNull;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, digits, locale);

  Future<void> _pickWallet(S s, bool hidden) async {
    final picked = await showWalletPicker(
      context,
      title: s.refundToWallet,
      wallets: _wallets,
      selected: walletId,
      digitsOf: digitsOf,
      hideBalances: hidden,
    );
    if (picked != null) setState(() => walletId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: on,
      today: model.today() ?? on,
    );
    if (picked != null) setState(() => on = picked);
  }

  Future<void> _save(String locale) async {
    final s = S.of(context);
    final value = _value(locale);
    final id = walletId;
    if (value == null || id == null) return;
    setState(() => saving = true);
    final saved = await model.refund(
      expense,
      clientId: clientId,
      accountId: id,
      amountMinor: value,
      occurredOn: on,
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }
    final failure = model.failure;
    showFreevaToast(
      context,
      message: failure?.code == AuthError.refundExceeds
          ? s.refundTooMuch
          : failure == null
          ? s.transactionError
          : transactionError(s, failure),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final label = widget.naming.label(expense);
    final left = expense.refundable;
    final value = _value(locale);
    final tooMuch = value != null && value > left;
    final ready =
        value != null &&
        value > BigInt.zero &&
        !tooMuch &&
        walletId != null &&
        !saving;
    final w = wallet;
    final month = parseCalendarParts(expense.occurredOn)?.month ?? 0;
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text(
              s.refundTitle(label.title),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FreevaTypography.titleL.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.refundSpent(
              formatMoneyText(label.minor, digits, locale),
              dayMonth(expense.occurredOn),
            ),
            textAlign: TextAlign.center,
            style: FreevaTypography.bodyS.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Column(
              children: [
                Text(
                  s.refundAmount,
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
                  symbol: MoneyDisplay.symbolFor(currency),
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FreevaChip(
              label: s.refundAll(formatMoneyText(left, digits, locale)),
              selected: false,
              onTap: () => setState(
                () => amount.text = formatMoneyText(left, digits, locale),
              ),
            ),
          ),
          const SizedBox(height: 18),
          PickerField(
            chevron: false,
            label: s.refundToWallet,
            value: w?.draft.name ?? s.recNeedWallet,
            placeholder: w == null,
            leading: FieldIconTile(
              icon: LucideIcons.creditCard,
              background: c.tintCyan,
              foreground: c.tintCyanFg,
            ),
            onTap: () => _pickWallet(s, hidden),
          ),
          const SizedBox(height: 18),
          PickerField(
            chevron: false,
            label: s.refundDate,
            value: on == model.today() ? s.txToday : dayMonth(on),
            leading: FieldIconTile(
              icon: LucideIcons.calendar,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Text(
            tooMuch ? s.refundTooMuch : s.refundHint(label.category, month),
            style: FreevaTypography.bodyS.copyWith(
              height: 18 / 13,
              color: tooMuch ? c.statusDanger : c.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          FreevaButton(
            label: s.refundSave,
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
