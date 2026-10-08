import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_editor.dart';
import 'transaction_fields.dart';
import 'transaction_labels.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    required this.model,
    this.existing,
    this.copy = false,
    super.key,
  });
  final TransactionViewModel model;
  final TransactionBundle? existing;
  final bool copy;
  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final amount = TextEditingController();
  final notes = TextEditingController();
  final rate = TextEditingController();
  late TransactionType type;
  late List<String> clientIds;
  String? accountId;
  String? counterAccountId;
  String? categoryId;
  String occurredOn = '';
  String? quotedAt;
  String rateSeed = '';
  bool invalid = false;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    final existing = widget.existing;
    final copy = widget.copy;
    type = existing?.type ?? TransactionType.expense;
    accountId =
        existing?.legs.first.accountId ?? widget.model.preferredAccountId();
    counterAccountId = existing != null && existing.legs.length > 1
        ? existing.legs[1].accountId
        : null;
    categoryId =
        existing?.categoryId ??
        (type == TransactionType.expense
            ? widget.model.preferredCategoryId()
            : null);
    occurredOn = existing?.occurredOn ?? widget.model.today() ?? '';
    notes.text = existing?.notes ?? '';
    quotedAt = existing?.fx?.quotedAt;
    rate.text = existing?.fx?.rate ?? '';
    rateSeed = rate.text;
    clientIds = existing != null && !copy
        ? existing.legs.map((leg) => leg.clientId).toList()
        : [widget.model.newClientId(), widget.model.newClientId()];
    if (type != TransactionType.transfer) clientIds = [clientIds.first];
    final source = _wallet(accountId);
    if (existing != null && source != null) {
      amount.text = formatMoneyText(
        existing.legs.first.amountMinor.abs(),
        _digits(source.draft.currency),
        Localizations.localeOf(context).toString(),
        grouped: false,
      );
    }
  }

  @override
  void dispose() {
    amount.dispose();
    notes.dispose();
    rate.dispose();
    super.dispose();
  }

  Wallet? _wallet(String? id) {
    for (final wallet in widget.model.wallets) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  int _digits(String code) {
    for (final currency in widget.model.currencies) {
      if (currency.code == code) return currency.minorDigits;
    }
    return 0;
  }

  Future<void> _save() async {
    final source = _wallet(accountId);
    final locale = Localizations.localeOf(context).toString();
    final parsed = source == null
        ? null
        : parseMoneyText(amount.text, _digits(source.draft.currency), locale);
    final sourceWallet = source;
    if (sourceWallet == null ||
        parsed == null ||
        parsed <= BigInt.zero ||
        accountId == null) {
      setState(() => invalid = true);
      return;
    }
    final destination = _wallet(counterAccountId);
    final cross =
        type == TransactionType.transfer &&
        destination != null &&
        sourceWallet.draft.currency != destination.draft.currency;
    if (cross && rate.text.trim() != rateSeed) {
      quotedAt = DateTime.now().toUtc().toIso8601String();
      rateSeed = rate.text.trim();
    }
    final draft = TransactionDraft(
      type: type,
      occurredOn: occurredOn,
      accountId: accountId!,
      counterAccountId: counterAccountId,
      magnitude: parsed,
      clientIds: clientIds,
      categoryId: type == TransactionType.transfer ? null : categoryId,
      notes: notes.text,
      rate: cross ? rate.text : null,
      quotedAt: cross ? quotedAt : null,
    );
    final saved = await widget.model.save(
      draft,
      existing: widget.copy ? null : widget.existing,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() => invalid = widget.model.failure != null);
    }
  }

  Future<void> _pickDate() async {
    final parts = occurredOn.split('-');
    final initial = parts.length == 3
        ? DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          )
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    final year = picked.year.toString().padLeft(4, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    setState(() => occurredOn = '$year-$month-$day');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final model = widget.model;
    final readOnly = widget.existing?.deleted == true && !widget.copy;
    final failure = model.failure;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        TransactionFields(
          type: type,
          lockedType: widget.existing != null && !widget.copy,
          readOnly: readOnly,
          accountId: accountId,
          counterAccountId: counterAccountId,
          categoryId: categoryId,
          occurredOn: occurredOn,
          amount: amount,
          notes: notes,
          rate: rate,
          wallets: model.wallets,
          currencies: model.currencies,
          categories: model.categories,
          recent: model.recentCategories,
          onType: (value) => setState(() {
            type = value;
            if (value == TransactionType.transfer && clientIds.length == 1) {
              clientIds = [...clientIds, model.newClientId()];
            }
            if (value != TransactionType.transfer) {
              clientIds = [clientIds.first];
            }
            if (value == TransactionType.expense && categoryId == null) {
              categoryId = model.preferredCategoryId();
            }
          }),
          onAccount: (value) => setState(() => accountId = value),
          onCounter: (value) => setState(() => counterAccountId = value),
          onCategory: (value) => setState(() => categoryId = value),
          onDate: _pickDate,
        ),
        if (invalid && failure != null)
          Text(
            transactionError(s, failure),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else if (invalid)
          Text(
            s.transactionInvalid,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (model.needsReload) Text(s.transactionReloadRequired),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            if (!readOnly)
              FilledButton(
                onPressed: model.busy || model.needsReload ? null : _save,
                child: Text(s.transactionSave),
              ),
            if (widget.existing != null && !widget.copy && !readOnly)
              OutlinedButton(
                onPressed: model.busy ? null : _delete,
                child: Text(s.transactionDelete),
              ),
            if (readOnly)
              FilledButton(
                onPressed: model.busy || model.needsReload ? null : _restore,
                child: Text(s.transactionRestore),
              ),
            if (widget.existing != null && !widget.copy)
              TextButton(
                onPressed: model.busy ? null : _copy,
                child: Text(s.transactionCopy),
              ),
          ],
        ),
      ],
      ),
    );
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final s = S.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.transactionDeleteTitle),
        content: Text(s.transactionDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.transactionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.transactionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final removed = await widget.model.remove(existing);
    if (removed && mounted) Navigator.of(context).pop();
  }

  Future<void> _restore() async {
    final existing = widget.existing;
    if (existing == null) return;
    final restored = await widget.model.restore(existing);
    if (restored && mounted) Navigator.of(context).pop();
  }

  void _copy() {
    final existing = widget.existing;
    if (existing == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditor(
          model: widget.model,
          initial: existing,
          copy: true,
        ),
      ),
    );
  }
}

