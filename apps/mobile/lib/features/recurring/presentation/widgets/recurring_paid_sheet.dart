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
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/sheet_amount_field.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_icon_tile.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/recurring_rule.dart';
import '../viewmodels/recurring_view_model.dart';
import 'recurring_expense_picker.dart';
import 'recurring_labels.dart';
import '../../../../core/money/currency_catalog.dart';

/// "Đã trả …?" over the list. Returns true once the due day is confirmed.
Future<bool?> showRecurringPaidSheet(
  BuildContext context,
  RecurringViewModel model,
  RecurringRule rule, {
  FinanceCategory? category,
}) => showFreevaSheet<bool>(
  context: context,
  builder: (context) =>
      _PaidSheet(model: model, rule: rule, category: category),
);

class _PaidSheet extends StatefulWidget {
  const _PaidSheet({
    required this.model,
    required this.rule,
    required this.category,
  });

  final RecurringViewModel model;
  final RecurringRule rule;
  final FinanceCategory? category;

  @override
  State<_PaidSheet> createState() => _PaidSheetState();
}

class _PaidSheetState extends State<_PaidSheet> {
  final amount = TextEditingController();
  String? walletId;
  late String paidOn = widget.model.today;
  bool saving = false;
  bool inited = false;

  RecurringViewModel get model => widget.model;
  RecurringRule get rule => widget.rule;

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  List<Wallet> get _wallets => [
    for (final w in model.wallets)
      if (w.draft.currency == rule.currencyCode) w,
  ];

  Wallet? get wallet => _wallets.where((w) => w.id == walletId).firstOrNull;

  void _init(String locale) {
    inited = true;
    amount.text = formatMoneyText(
      rule.amountMinor.abs(),
      model.digitsOf(rule.currencyCode),
      locale,
    );
    final mine = _wallets.where((w) => w.id == rule.accountId).firstOrNull;
    walletId = (mine ?? _wallets.firstOrNull)?.id;
  }

  BigInt? _value(String locale) =>
      parseGroupedMoney(amount.text, model.digitsOf(rule.currencyCode), locale);

  Future<void> _pickWallet(S s, bool hidden) async {
    final picked = await showWalletPicker(
      context,
      title: s.recPayFrom,
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

  Future<void> _finish(RecurringConfirm confirm) async {
    final s = S.of(context);
    setState(() => saving = true);
    final done = await model.confirm(rule, confirm);
    if (!mounted) return;
    setState(() => saving = false);
    if (done != null) {
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

  Future<void> _submit(String locale) async {
    final value = _value(locale);
    final id = walletId;
    if (value == null || value <= BigInt.zero || id == null) return;
    await _finish(
      RecurringConfirm(
        occurredOn: rule.nextExecutionDate,
        accountId: id,
        amountMinor: value == rule.amountMinor.abs() ? null : value,
        paidOn: paidOn == model.today ? null : paidOn,
      ),
    );
  }

  Future<void> _link() async {
    final picked = await showRecurringExpensePicker(context, model);
    if (picked == null || !mounted) return;
    await _finish(
      RecurringConfirm(
        occurredOn: rule.nextExecutionDate,
        transactionId: picked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    if (!inited) _init(locale);
    final value = _value(locale);
    final ready =
        value != null && value > BigInt.zero && walletId != null && !saving;
    final symbol = CurrencyCatalog.current.symbol(rule.currencyCode);
    final title = ruleTitle(s, rule, widget.category);
    return BalancesHiddenBuilder(
      builder: (context, hidden) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CategoryIconTile(
              iconToken: widget.category?.iconToken ?? 'bills',
              colorToken: widget.category?.colorToken,
              size: 48,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            s.recPaidTitle(title),
            textAlign: TextAlign.center,
            style: FreevaTypography.titleM.copyWith(
              height: 1.21,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dueLine(
              s,
              rule,
              digits: model.digitsOf(rule.currencyCode),
              locale: locale,
            ),
            textAlign: TextAlign.center,
            style: FreevaTypography.bodyS.copyWith(
              height: 1.21,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              s.recRealAmount,
              style: FreevaTypography.bodyS.copyWith(
                height: 1.21,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: SheetAmountField(
              controller: amount,
              digits: model.digitsOf(rule.currencyCode),
              locale: locale,
              symbol: symbol,
              onChanged: () => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          PickerField(
            chevron: false,
            label: s.recPayFrom,
            value: wallet?.draft.name ?? s.recNeedWallet,
            placeholder: wallet == null,
            leading: wallet == null
                ? FieldIconTile(
                    icon: LucideIcons.landmark,
                    background: c.tintBlue,
                    foreground: c.tintBlueFg,
                  )
                : WalletTypeIcon(type: wallet!.draft.type, size: 32),
            onTap: () => _pickWallet(s, hidden),
          ),
          const SizedBox(height: 14),
          PickerField(
            chevron: false,
            label: s.recPaidOn,
            value: paidOn == model.today ? s.txToday : dayMonth(paidOn),
            leading: FieldIconTile(
              icon: LucideIcons.calendar,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          FreevaButton(
            label: s.recConfirm,
            size: FreevaButtonSize.l,
            expand: true,
            loading: saving,
            onPressed: ready ? () => _submit(locale) : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: saving ? null : _link,
              borderRadius: BorderRadius.circular(FreevaRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  s.recLinkExisting,
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
      ),
    );
  }
}
