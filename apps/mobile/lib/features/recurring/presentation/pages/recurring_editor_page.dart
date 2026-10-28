import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/viewmodels/category_view_model.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../wallets/domain/wallet.dart';
import '../../../wallets/presentation/viewmodels/wallet_view_model.dart';
import '../../domain/recurring_rule.dart';
import '../viewmodels/recurring_view_model.dart';

class RecurringEditorPage extends StatefulWidget {
  const RecurringEditorPage({this.ruleId, super.key});

  final String? ruleId;

  @override
  State<RecurringEditorPage> createState() => _RecurringEditorPageState();
}

class _RecurringEditorPageState extends State<RecurringEditorPage> {
  final model = getIt<RecurringViewModel>();
  final walletsVm = getIt<WalletViewModel>();
  final categoriesVm = getIt<CategoryViewModel>();
  final profile = getIt<ProfileViewModel>();

  String type = 'expense';
  String unit = 'month';
  int interval = 1;
  String? accountId;
  String? counterAccountId;
  String? categoryId;
  late final TextEditingController amount;
  late final TextEditingController start;
  late final TextEditingController next;
  late final TextEditingController end;
  bool active = true;
  bool saving = false;
  bool ready = false;
  RecurringRule? existing;

  @override
  void initState() {
    super.initState();
    final today =
        calendarDate(
          DateTime.now(),
          profile.saved?.timezone ?? 'Asia/Ho_Chi_Minh',
        ) ??
        DateTime.now().toIso8601String().substring(0, 10);
    amount = TextEditingController();
    start = TextEditingController(text: today);
    next = TextEditingController(text: today);
    end = TextEditingController();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await Future.wait([walletsVm.load(), categoriesVm.load(), model.load()]);
    if (!mounted) return;
    final id = widget.ruleId;
    if (id != null) {
      existing = model.rules.where((r) => r.id == id).firstOrNull;
      final rule = existing;
      if (rule != null) {
        type = rule.type;
        unit = rule.unit;
        interval = rule.interval;
        accountId = rule.accountId;
        counterAccountId = rule.counterAccountId;
        categoryId = rule.categoryId;
        amount.text = formatMoneyText(
          rule.amountMinor.abs(),
          0,
          Localizations.localeOf(context).toString(),
          grouped: false,
        );
        start.text = rule.startDate;
        next.text = rule.nextExecutionDate;
        end.text = rule.endDate ?? '';
        active = rule.active;
      }
    }
    accountId ??= walletsVm.active.firstOrNull?.id;
    setState(() => ready = true);
  }

  @override
  void dispose() {
    amount.dispose();
    start.dispose();
    next.dispose();
    end.dispose();
    super.dispose();
  }

  List<Wallet> get _wallets => walletsVm.active;
  List<FinanceCategory> get _categories => [
    for (final item in categoriesVm.categories)
      if (!item.archived && item.kind.fits(false)) item,
  ];

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final magnitude = parseMoneyText(amount.text, 0, locale);
    if (magnitude == null || magnitude <= BigInt.zero || accountId == null) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    if (type == 'expense' && categoryId == null) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    final signed = type == 'income' ? magnitude : -magnitude;
    final currency =
        _wallets.where((w) => w.id == accountId).firstOrNull?.draft.currency ??
        profile.saved?.currency ??
        'VND';
    BigInt? counterAmount;
    String? counterCurrency;
    if (type == 'transfer') {
      if (counterAccountId == null || counterAccountId == accountId) {
        showFreevaToast(context, message: s.meSaveError);
        return;
      }
      counterAmount = magnitude;
      counterCurrency = _wallets
          .where((w) => w.id == counterAccountId)
          .firstOrNull
          ?.draft
          .currency;
      if (counterCurrency == null || counterCurrency != currency) {
        showFreevaToast(context, message: s.meSaveError);
        return;
      }
    }
    final draft = RecurringDraft(
      clientId: existing?.clientId ?? model.newClientId(),
      type: existing?.type ?? type,
      unit: unit,
      interval: interval,
      amountMinor: signed,
      currencyCode: currency,
      accountId: accountId!,
      categoryId: type == 'expense' ? categoryId : null,
      counterAccountId: type == 'transfer' ? counterAccountId : null,
      counterAmountMinor: type == 'transfer' ? counterAmount : null,
      counterCurrencyCode: type == 'transfer' ? counterCurrency : null,
      fxRate: null,
      startDate: start.text.trim(),
      endDate: end.text.trim().isEmpty ? null : end.text.trim(),
      nextExecutionDate: next.text.trim(),
      active: active,
    );
    setState(() => saving = true);
    final ok = existing == null
        ? await model.create(draft)
        : await model.save(existing!, draft);
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
    final ok = await model.delete(rule);
    if (!mounted) return;
    if (ok) {
      context.pop();
      return;
    }
    showFreevaToast(context, message: S.of(context).meSaveError);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!ready) {
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.recurringAdd,
          onLeading: () => context.popOrGo('/me/recurring'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: FreevaTopBar(
        title: existing == null ? s.recurringAdd : s.recurringEdit,
        onLeading: () => context.popOrGo('/me/recurring'),
        action: existing == null
            ? null
            : FreevaIconButton(
                icon: LucideIcons.trash2,
                label: s.recurringDelete,
                onPressed: saving ? null : _delete,
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FreevaSpace.s4),
        children: [
          if (existing == null)
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'expense',
                  label: Text(s.recurringTypeExpense),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text(s.recurringTypeIncome),
                ),
                ButtonSegment(
                  value: 'transfer',
                  label: Text(s.recurringTypeTransfer),
                ),
              ],
              selected: {type},
              onSelectionChanged: (value) => setState(() {
                type = value.first;
                if (type != 'expense') categoryId = null;
                if (type != 'transfer') counterAccountId = null;
              }),
            ),
          const SizedBox(height: FreevaSpace.s4),
          FreevaTextField(
            controller: amount,
            label: s.recurringAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: FreevaSpace.s3),
          DropdownButtonFormField<String>(
            key: ValueKey('account-$accountId'),
            initialValue: accountId,
            decoration: InputDecoration(labelText: s.recurringWallet),
            items: [
              for (final wallet in _wallets)
                DropdownMenuItem(
                  value: wallet.id,
                  child: Text(wallet.draft.name),
                ),
            ],
            onChanged: (value) => setState(() => accountId = value),
          ),
          if (type == 'transfer') ...[
            const SizedBox(height: FreevaSpace.s3),
            DropdownButtonFormField<String>(
              key: ValueKey('counter-$counterAccountId'),
              initialValue: counterAccountId,
              decoration: InputDecoration(labelText: s.recurringCounterWallet),
              items: [
                for (final wallet in _wallets)
                  if (wallet.id != accountId)
                    DropdownMenuItem(
                      value: wallet.id,
                      child: Text(wallet.draft.name),
                    ),
              ],
              onChanged: (value) => setState(() => counterAccountId = value),
            ),
          ],
          if (type == 'expense') ...[
            const SizedBox(height: FreevaSpace.s3),
            DropdownButtonFormField<String>(
              key: ValueKey('category-$categoryId'),
              initialValue: categoryId,
              decoration: InputDecoration(labelText: s.recurringCategory),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) => setState(() => categoryId = value),
            ),
          ],
          const SizedBox(height: FreevaSpace.s3),
          DropdownButtonFormField<String>(
            key: ValueKey('unit-$unit'),
            initialValue: unit,
            decoration: InputDecoration(labelText: s.recurringFrequency),
            items: [
              DropdownMenuItem(value: 'day', child: Text(s.recurringUnitDay)),
              DropdownMenuItem(value: 'week', child: Text(s.recurringUnitWeek)),
              DropdownMenuItem(
                value: 'month',
                child: Text(s.recurringUnitMonth),
              ),
              DropdownMenuItem(value: 'year', child: Text(s.recurringUnitYear)),
            ],
            onChanged: (value) => setState(() => unit = value ?? unit),
          ),
          const SizedBox(height: FreevaSpace.s3),
          DropdownButtonFormField<int>(
            key: ValueKey('interval-$interval'),
            initialValue: interval,
            decoration: InputDecoration(labelText: s.recurringInterval),
            items: [
              for (var i = 1; i <= 12; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (value) => setState(() => interval = value ?? 1),
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaTextField(
            controller: start,
            label: s.recurringStart,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaTextField(
            controller: next,
            label: s.recurringNextLabel,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaTextField(
            controller: end,
            label: s.recurringEnd,
            keyboardType: TextInputType.datetime,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(s.recurringActive),
            value: active,
            onChanged: (value) => setState(() => active = value),
          ),
          const SizedBox(height: FreevaSpace.s4),
          FreevaButton(
            label: s.recurringSave,
            onPressed: saving ? null : _save,
            loading: saving,
          ),
        ],
      ),
    );
  }
}
