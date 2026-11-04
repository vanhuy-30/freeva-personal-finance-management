import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_input_formatter.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_chip.dart';
import '../../../../core/widgets/freeva_dialog.dart';
import '../../../../core/widgets/freeva_picker_field.dart';
import '../../../../core/widgets/freeva_segmented.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/viewmodels/category_view_model.dart';
import '../../../categories/presentation/widgets/category_badge.dart'
    show categoryIcon;
import '../../../categories/presentation/widgets/category_icon_tile.dart';
import '../../../settings/presentation/widgets/balances_hidden_builder.dart';
import '../../../transactions/presentation/widgets/composer/category_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/date_picker_sheet.dart';
import '../../../transactions/presentation/widgets/composer/wallet_picker_sheet.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/widgets/editor/form_pair.dart';
import '../../../wallets/presentation/widgets/wallet_type_icon.dart';
import '../../domain/recurring_rule.dart';
import '../viewmodels/recurring_view_model.dart';
import '../widgets/rec_mode_group.dart';
import '../widgets/rec_repeat_sheet.dart';
import '../widgets/rec_switch_card.dart';
import '../widgets/recurring_labels.dart';

/// Thêm / Sửa định kỳ. A new rule picks Chi · Thu · Chuyển and how it is
/// recorded (auto, or ask first for a bill); an existing rule keeps both
/// (the API cannot change them).
class RecurringEditorPage extends StatefulWidget {
  const RecurringEditorPage({this.ruleId, super.key});

  final String? ruleId;

  @override
  State<RecurringEditorPage> createState() => _RecurringEditorPageState();
}

class _RecurringEditorPageState extends State<RecurringEditorPage> {
  final model = getIt<RecurringViewModel>();
  final categoriesVm = getIt<CategoryViewModel>();

  final name = TextEditingController();
  final amount = TextEditingController();
  String type = 'expense';
  bool remind = true;
  bool varies = false;
  bool active = true;
  RecRepeat repeat = (unit: 'month', interval: 1);
  int remindBefore = 3;
  String next = '';
  String? accountId;
  String? counterAccountId;
  String? categoryId;
  bool saving = false;
  bool ready = false;
  RecurringRule? existing;

  bool get editing => widget.ruleId != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await Future.wait([model.loadWallets(), categoriesVm.load(), model.load()]);
    if (!mounted) return;
    final locale = Localizations.localeOf(context).toString();
    next = model.today;
    final rule = editing
        ? model.rules.where((r) => r.id == widget.ruleId).firstOrNull
        : null;
    existing = rule;
    if (rule != null) {
      type = rule.type;
      remind = rule.isRemind;
      varies = rule.amountKind == 'estimated';
      active = rule.active;
      repeat = (
        unit: rule.isOneOff ? null : rule.unit,
        interval: rule.interval,
      );
      remindBefore = rule.remindDaysBefore;
      next = rule.nextExecutionDate;
      accountId = rule.accountId;
      counterAccountId = rule.counterAccountId;
      categoryId = rule.categoryId;
      name.text = rule.name ?? '';
      amount.text = formatMoneyText(
        rule.amountMinor.abs(),
        model.digitsOf(rule.currencyCode),
        locale,
      );
    }
    accountId ??= model.wallets.firstOrNull?.id;
    setState(() => ready = true);
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    super.dispose();
  }

  Wallet? _wallet(String? id) =>
      model.wallets.where((w) => w.id == id).firstOrNull;

  String get _currency =>
      _wallet(accountId)?.draft.currency ??
      existing?.currencyCode ??
      model.totalCurrency;

  List<FinanceCategory> get _categories => [
    for (final item in categoriesVm.categories)
      if (!item.archived && item.kind.fits(false)) item,
  ];

  FinanceCategory? get _category =>
      categoriesVm.categories.where((c) => c.id == categoryId).firstOrNull;

  void _pickType(String value) => setState(() {
    type = value;
    if (value != 'expense') {
      remind = false;
      categoryId = null;
      if (repeat.unit == null) repeat = (unit: 'month', interval: 1);
    }
    if (value != 'transfer') counterAccountId = null;
  });

  Future<void> _pickWallet(S s, bool hidden, {required bool counter}) async {
    final wallets = [
      for (final w in model.wallets)
        if (!counter || w.id != accountId) w,
    ];
    final picked = await showWalletPicker(
      context,
      title: counter ? s.recurringCounterWallet : s.recPayFrom,
      wallets: wallets,
      selected: counter ? counterAccountId : accountId,
      digitsOf: model.digitsOf,
      hideBalances: hidden,
    );
    if (picked == null) return;
    setState(() => counter ? counterAccountId = picked : accountId = picked);
  }

  Future<void> _pickCategory() async {
    final picked = await showCategoryPicker(
      context,
      categories: _categories,
      frequent: const [],
      selected: categoryId,
    );
    if (picked != null) setState(() => categoryId = picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePickerSheet(
      context,
      value: next,
      today: model.today,
    );
    if (picked != null) setState(() => next = picked);
  }

  Future<void> _pickRepeat() async {
    final picked = await showRecRepeatSheet(
      context,
      current: repeat,
      allowOnce: remind,
    );
    if (picked != null) setState(() => repeat = picked);
  }

  RecurringDraft? _draft(S s, String locale) {
    final currency = _currency;
    final magnitude = parseGroupedMoney(
      amount.text,
      model.digitsOf(currency),
      locale,
    );
    final label = name.text.trim();
    if (magnitude == null || magnitude <= BigInt.zero) return null;
    if (remind && label.isEmpty) return null;
    if (!remind && accountId == null) return null;
    BigInt? counterAmount;
    String? counterCurrency;
    if (type == 'transfer') {
      counterAmount = magnitude;
      counterCurrency = _wallet(counterAccountId)?.draft.currency;
      if (counterAccountId == null || counterCurrency != currency) return null;
    }
    final once = repeat.unit == null;
    final old = existing;
    return RecurringDraft(
      clientId: old?.clientId ?? model.newClientId(),
      type: type,
      mode: remind ? 'remind' : 'auto',
      name: label.isEmpty ? null : label,
      amountKind: remind && varies ? 'estimated' : 'fixed',
      remindDaysBefore: remindBefore,
      repeat: !once,
      unit: repeat.unit ?? 'month',
      interval: repeat.interval,
      amountMinor: type == 'income' ? magnitude : -magnitude,
      currencyCode: currency,
      accountId: accountId,
      categoryId: type == 'expense' ? categoryId : null,
      counterAccountId: counterAccountId,
      counterAmountMinor: counterAmount,
      counterCurrencyCode: counterCurrency,
      fxRate: null,
      startDate: old != null && !once ? old.startDate : next,
      endDate: once
          ? next
          : (old != null && !old.isOneOff ? old.endDate : null),
      nextExecutionDate: next,
      active: active,
    );
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final draft = _draft(s, locale);
    if (draft == null) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    setState(() => saving = true);
    final old = existing;
    final ok = old == null
        ? await model.create(draft)
        : await model.save(old, draft);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      context.pop();
      return;
    }
    showFreevaToast(
      context,
      message: model.failure?.code == AuthError.conflict
          ? s.meConflict
          : s.meSaveError,
    );
  }

  Future<void> _delete() async {
    final rule = existing;
    if (rule == null) return;
    final s = S.of(context);
    final sure = await showFreevaConfirm(
      context: context,
      title: s.recRemove,
      message: s.recRemoveBody,
      cancelLabel: s.commonCancel,
      confirmLabel: s.recRemove,
    );
    if (!sure || !mounted) return;
    setState(() => saving = true);
    final ok = await model.delete(rule);
    if (!mounted) return;
    setState(() => saving = false);
    if (ok) {
      context.pop();
      return;
    }
    showFreevaToast(context, message: s.meSaveError);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final margin = context.screenMargin;
    final old = existing;
    final title = old == null
        ? s.recurringAdd
        : ruleTitle(
            s,
            old,
            categoriesVm.categories
                .where((c) => c.id == old.categoryId)
                .firstOrNull,
          );
    return Scaffold(
      appBar: FreevaTopBar(
        title: title,
        kind: FreevaTopBarKind.modal,
        onLeading: () => context.popOrGo('/me/recurring'),
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _form(context, s, margin)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    margin,
                    0,
                    margin,
                    editing ? 8 : 28,
                  ),
                  child: FreevaButton(
                    label: s.recurringSave,
                    size: FreevaButtonSize.l,
                    expand: true,
                    loading: saving,
                    onPressed: saving ? null : _save,
                  ),
                ),
                if (editing) _RemoveLink(onTap: saving ? null : _delete),
              ],
            ),
    );
  }

  Widget _form(BuildContext context, S s, double margin) {
    final c = context.colors;
    final locale = Localizations.localeOf(context).toString();
    final digits = model.digitsOf(_currency);
    final wallet = _wallet(accountId);
    final counter = _wallet(counterAccountId);
    final category = _category;
    final once = repeat.unit == null;
    return ListView(
      padding: EdgeInsets.fromLTRB(margin, FreevaSpace.s2, margin, 14),
      children: [
        IgnorePointer(
          ignoring: editing,
          child: FreevaSegmented<String>(
            expand: true,
            selected: type,
            segments: [
              FreevaSegment('expense', s.recurringTypeExpense),
              FreevaSegment('income', s.recurringTypeIncome),
              FreevaSegment('transfer', s.recurringTypeTransfer),
            ],
            onChanged: _pickType,
          ),
        ),
        const SizedBox(height: 14),
        RecModeGroup(
          remind: remind,
          remindEnabled: type == 'expense',
          onChanged: editing ? null : (value) => setState(() => remind = value),
        ),
        const SizedBox(height: 14),
        FreevaTextField(
          label: s.recName,
          controller: name,
          maxLength: 80,
          leadingIcon: category == null
              ? LucideIcons.receiptText
              : categoryIcon(category.iconToken),
          leadingTint: category == null
              ? null
              : categoryTwoTone(context, category.colorToken),
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        FreevaTextField(
          label: s.recurringAmount,
          controller: amount,
          tabular: true,
          keyboardType: TextInputType.numberWithOptions(decimal: digits > 0),
          inputFormatters: [
            MoneyInputFormatter(minorDigits: digits, locale: locale),
            LengthLimitingTextInputFormatter(24),
          ],
          onChanged: (_) => setState(() {}),
        ),
        if (remind) ...[
          const SizedBox(height: 8),
          RecSwitchCard(
            title: s.recVaries,
            hint: s.recVariesSub,
            value: varies,
            onChanged: (v) => setState(() => varies = v),
          ),
        ],
        const SizedBox(height: 14),
        FormPair(
          first: PickerField(
            chevron: false,
            label: s.recRepeat,
            value: repeatLabel(
              s,
              once: once,
              unit: repeat.unit ?? 'month',
              interval: repeat.interval,
            ),
            leading: FieldIconTile(
              icon: LucideIcons.repeat,
              background: c.bgSubtle,
              foreground: c.textOnWash,
            ),
            onTap: _pickRepeat,
          ),
          second: PickerField(
            chevron: false,
            label: editing ? s.recNextRun : s.recFirstDue,
            value: dayMonth(next),
            leading: remind
                ? FieldIconTile(
                    icon: LucideIcons.calendarClock,
                    background: c.statusWarningBg,
                    foreground: c.statusWarning,
                  )
                : FieldIconTile(
                    icon: LucideIcons.calendar,
                    background: c.bgSubtle,
                    foreground: c.textOnWash,
                  ),
            onTap: _pickDate,
          ),
        ),
        if (remind) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              s.recRemindBefore,
              style: FreevaTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: FreevaSpace.s2,
            runSpacing: FreevaSpace.s2,
            children: [
              for (final days in const [0, 1, 3, 7])
                FreevaChip(
                  label: days == 0
                      ? s.recRemindSameDay
                      : s.recRemindDaysShort(days),
                  selected: remindBefore == days,
                  onTap: () => setState(() => remindBefore = days),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        BalancesHiddenBuilder(
          builder: (context, hidden) => PickerField(
            chevron: false,
            label: remind ? s.recPayFrom : s.recurringWallet,
            value: wallet?.draft.name ?? s.recNeedWallet,
            placeholder: wallet == null,
            leading: wallet == null
                ? FieldIconTile(
                    icon: LucideIcons.landmark,
                    background: c.tintBlue,
                    foreground: c.tintBlueFg,
                  )
                : WalletTypeIcon(type: wallet.draft.type, size: 32),
            onTap: () => _pickWallet(s, hidden, counter: false),
          ),
        ),
        if (type == 'transfer') ...[
          const SizedBox(height: 14),
          BalancesHiddenBuilder(
            builder: (context, hidden) => PickerField(
              chevron: false,
              label: s.recurringCounterWallet,
              value: counter?.draft.name ?? s.recNeedWallet,
              placeholder: counter == null,
              leading: counter == null
                  ? FieldIconTile(
                      icon: LucideIcons.landmark,
                      background: c.tintBlue,
                      foreground: c.tintBlueFg,
                    )
                  : WalletTypeIcon(type: counter.draft.type, size: 32),
              onTap: () => _pickWallet(s, hidden, counter: true),
            ),
          ),
        ],
        if (type == 'expense') ...[
          const SizedBox(height: 14),
          PickerField(
            chevron: false,
            label: s.recurringCategory,
            value: category?.name ?? s.recNeedCategory,
            placeholder: category == null,
            leading: category == null
                ? FieldIconTile(
                    icon: LucideIcons.layoutGrid,
                    background: c.bgSubtle,
                    foreground: c.textOnWash,
                  )
                : CategoryIconTile(
                    iconToken: category.iconToken,
                    colorToken: category.colorToken,
                    size: 32,
                  ),
            onTap: _pickCategory,
          ),
        ],
        if (editing) ...[
          const SizedBox(height: 14),
          RecSwitchCard(
            title: s.recPause,
            hint: s.recPauseSub,
            value: !active,
            onChanged: (v) => setState(() => active = !v),
          ),
        ],
      ],
    );
  }
}

/// Red "Xoá định kỳ" under Lưu (RecEditAuto): 15/600, 6 padding.
class _RemoveLink extends StatelessWidget {
  const _RemoveLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          s.recRemove,
          style: FreevaTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colors.statusDanger,
          ),
        ),
      ),
    );
  }
}
