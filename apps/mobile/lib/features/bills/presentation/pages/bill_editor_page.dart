import 'package:flutter/material.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/router/nav_back.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/widgets/freeva_button.dart';
import '../../../../core/widgets/freeva_icon_button.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_text_field.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../../core/widgets/freeva_top_bar.dart';
import '../../../auth/domain/auth_repository.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../recurring/domain/recurring_rule.dart';
import '../../../recurring/presentation/viewmodels/recurring_view_model.dart';
import '../../../transactions/domain/transaction.dart';
import '../../domain/bill.dart';
import '../viewmodels/bill_view_model.dart';

class BillEditorPage extends StatefulWidget {
  const BillEditorPage({this.billId, super.key});

  final String? billId;

  @override
  State<BillEditorPage> createState() => _BillEditorPageState();
}

class _BillEditorPageState extends State<BillEditorPage> {
  final model = getIt<BillViewModel>();
  final recurring = getIt<RecurringViewModel>();
  final profile = getIt<ProfileViewModel>();

  late final TextEditingController name;
  late final TextEditingController amount;
  late final TextEditingController dueOn;
  String amountKind = 'fixed';
  String? recurringRuleId;
  bool saving = false;
  bool ready = false;
  Bill? existing;

  @override
  void initState() {
    super.initState();
    final today =
        calendarDate(
          DateTime.now(),
          profile.saved?.timezone ?? 'Asia/Ho_Chi_Minh',
        ) ??
        DateTime.now().toIso8601String().substring(0, 10);
    name = TextEditingController();
    amount = TextEditingController();
    dueOn = TextEditingController(text: today);
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await Future.wait([model.load(), recurring.load()]);
    if (!mounted) return;
    final id = widget.billId;
    if (id != null) {
      existing = model.bills.where((b) => b.id == id).firstOrNull;
      final bill = existing;
      if (bill != null) {
        name.text = bill.name;
        amount.text = formatMoneyText(
          bill.amountMinor,
          0,
          Localizations.localeOf(context).toString(),
          grouped: false,
        );
        dueOn.text = bill.dueOn;
        amountKind = bill.amountKind;
        recurringRuleId = bill.recurringRuleId;
      }
    }
    setState(() => ready = true);
  }

  @override
  void dispose() {
    name.dispose();
    amount.dispose();
    dueOn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final magnitude = parseMoneyText(amount.text, 0, locale);
    final label = name.text.trim();
    if (magnitude == null || magnitude <= BigInt.zero || label.isEmpty) {
      showFreevaToast(context, message: s.billsInvalid);
      return;
    }
    final currency = profile.saved?.currency ?? 'VND';
    final draft = BillDraft(
      clientId: existing?.clientId ?? model.newClientId(),
      name: label,
      dueOn: dueOn.text.trim(),
      amountMinor: magnitude,
      amountKind: amountKind,
      currencyCode: currency,
      recurringRuleId: recurringRuleId,
    );
    setState(() => saving = true);
    final ok = existing == null
        ? await model.create(draft)
        : await model.save(existing!, draft);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      final conflict = model.failure?.code == AuthError.conflict;
      showFreevaToast(
        context,
        message: conflict ? s.meConflict : s.meSaveError,
      );
      return;
    }
    context.popOrGo('/me/bills');
  }

  Future<void> _delete() async {
    final bill = existing;
    if (bill == null) return;
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await model.delete(bill);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    context.popOrGo('/me/bills');
  }

  Future<void> _pickRule() async {
    final s = S.of(context);
    final picked = await showFreevaSheet<String?>(
      context: context,
      title: s.billsRecurring,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(s.billsOneOff),
            onTap: () => Navigator.pop(context, ''),
          ),
          for (final rule in recurring.rules)
            ListTile(
              title: Text(_ruleLabel(rule)),
              onTap: () => Navigator.pop(context, rule.id),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() => recurringRuleId = picked.isEmpty ? null : picked);
  }

  String _ruleLabel(RecurringRule rule) {
    final amount = formatMoneyText(
      rule.amountMinor.abs(),
      0,
      Localizations.localeOf(context).toString(),
    );
    return '$amount ${rule.currencyCode} · ${rule.nextExecutionDate}';
  }

  Future<void> _markPaid() async {
    final bill = existing;
    if (bill == null) return;
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    final result = await model.recentTransactions();
    if (!mounted) return;
    final legs = result.fold<List<TxLeg>?>((_) {
      showFreevaToast(context, message: s.meSaveError);
      return null;
    }, (value) => value);
    if (legs == null) return;
    if (legs.isEmpty) {
      showFreevaToast(context, message: s.billsNoTransactions);
      return;
    }
    final picked = await showFreevaSheet<String>(
      context: context,
      title: s.billsPickTransaction,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final leg in legs)
            ListTile(
              title: Text(
                '${formatMoneyText(leg.amountMinor.abs(), 0, locale)} ${leg.currencyCode}',
              ),
              subtitle: Text(
                '${leg.occurredOn}${leg.merchant == null ? '' : ' · ${leg.merchant}'}',
              ),
              onTap: () => Navigator.pop(context, leg.id),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => saving = true);
    final ok = await model.markPaid(bill, picked);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    existing = model.bills.where((b) => b.id == bill.id).firstOrNull;
    setState(() {});
    showFreevaToast(context, message: s.billsMarkedPaid);
  }

  Future<void> _clearPaid() async {
    final bill = existing;
    if (bill == null) return;
    final s = S.of(context);
    setState(() => saving = true);
    final ok = await model.clearPaid(bill);
    if (!mounted) return;
    setState(() => saving = false);
    if (!ok) {
      showFreevaToast(context, message: s.meSaveError);
      return;
    }
    existing = model.bills.where((b) => b.id == bill.id).firstOrNull;
    setState(() {});
    showFreevaToast(context, message: s.billsClearedPaid);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (!ready) {
      return Scaffold(
        appBar: FreevaTopBar(
          title: s.billsAdd,
          onLeading: () => context.popOrGo('/me/bills'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final bill = existing;
    final ruleLabel = recurringRuleId == null
        ? s.billsOneOff
        : recurring.rules
                  .where((r) => r.id == recurringRuleId)
                  .map(_ruleLabel)
                  .firstOrNull ??
              s.billsLinkedRecurring;
    return Scaffold(
      appBar: FreevaTopBar(
        title: bill == null ? s.billsAdd : s.billsEdit,
        onLeading: () => context.popOrGo('/me/bills'),
        action: bill == null
            ? null
            : FreevaIconButton(
                icon: LucideIcons.trash2,
                label: s.billsDelete,
                onPressed: saving ? null : _delete,
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(FreevaSpace.s4),
        children: [
          FreevaTextField(controller: name, label: s.billsName),
          const SizedBox(height: FreevaSpace.s3),
          FreevaTextField(
            controller: amount,
            label: s.billsAmount,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: FreevaSpace.s3),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'fixed', label: Text(s.billsAmountFixed)),
              ButtonSegment(
                value: 'estimated',
                label: Text(s.billsAmountEstimated),
              ),
            ],
            selected: {amountKind},
            onSelectionChanged: (value) =>
                setState(() => amountKind = value.first),
          ),
          const SizedBox(height: FreevaSpace.s3),
          FreevaTextField(controller: dueOn, label: s.billsDueOn),
          const SizedBox(height: FreevaSpace.s3),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.billsRecurring),
            subtitle: Text(ruleLabel),
            trailing: const Icon(LucideIcons.chevronRight),
            onTap: _pickRule,
          ),
          if (bill != null) ...[
            const SizedBox(height: FreevaSpace.s4),
            if (bill.paid)
              FreevaButton(
                label: s.billsUnpay,
                onPressed: saving ? null : _clearPaid,
              )
            else
              FreevaButton(
                label: s.billsMarkPaid,
                onPressed: saving ? null : _markPaid,
              ),
          ],
          const SizedBox(height: FreevaSpace.s4),
          FreevaButton(label: s.billsSave, onPressed: saving ? null : _save),
        ],
      ),
    );
  }
}
