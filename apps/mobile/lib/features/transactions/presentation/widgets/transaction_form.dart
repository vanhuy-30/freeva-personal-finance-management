import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_editor.dart';
import 'transaction_fields.dart';
import 'transaction_labels.dart';
import 'transaction_tags_section.dart';

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
  final merchant = TextEditingController();
  final rate = TextEditingController();
  late TransactionType type;
  late List<String> clientIds;
  late List<String> tagIds;
  String? accountId;
  String? counterAccountId;
  String? categoryId;
  String occurredOn = '';
  String? quotedAt;
  String rateSeed = '';
  bool invalid = false;
  bool ready = false;
  bool accountTouched = false;
  bool categoryTouched = false;

  bool get _isNew => widget.existing == null || widget.copy;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_syncDefaults);
  }

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
    merchant.text = existing?.merchant ?? '';
    tagIds = List.of(existing?.tagIds ?? const []);
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

  void _syncDefaults() {
    if (!_isNew || !mounted) return;
    var changed = false;
    if (!accountTouched) {
      final preferred = widget.model.preferredAccountId();
      if (preferred != null && preferred != accountId) {
        accountId = preferred;
        changed = true;
      }
    }
    if (!categoryTouched && type == TransactionType.expense) {
      final preferred = widget.model.preferredCategoryId();
      if (preferred != null && preferred != categoryId) {
        categoryId = preferred;
        changed = true;
      }
    }
    if (changed) setState(() {});
  }

  @override
  void dispose() {
    widget.model.removeListener(_syncDefaults);
    amount.dispose();
    notes.dispose();
    merchant.dispose();
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
      merchant: type == TransactionType.transfer ? null : merchant.text,
      tagIds: tagIds,
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

  Widget _actions(S s, TransactionViewModel model, bool readOnly) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Wrap(
        spacing: 12,
        children: [
          if (!readOnly)
            FilledButton(
              onPressed: model.canWrite ? _save : null,
              child: Text(s.transactionSave),
            ),
          if (widget.existing != null && !widget.copy && !readOnly)
            OutlinedButton(
              onPressed: model.canWrite ? _delete : null,
              child: Text(s.transactionDelete),
            ),
          if (readOnly)
            FilledButton(
              onPressed: model.canWrite ? _restore : null,
              child: Text(s.transactionRestore),
            ),
          if (widget.existing != null && !widget.copy)
            TextButton(
              onPressed: model.busy ? null : _copy,
              child: Text(s.transactionCopy),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final model = widget.model;
    final readOnly = widget.existing?.deleted == true && !widget.copy;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final failure = model.failure;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TransactionFields(
                      type: type,
                      lockedType: widget.existing != null && !widget.copy,
                      readOnly: readOnly,
                      autofocusAmount: _isNew && !readOnly,
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
                        if (value == TransactionType.transfer &&
                            clientIds.length == 1) {
                          clientIds = [...clientIds, model.newClientId()];
                        }
                        if (value != TransactionType.transfer) {
                          clientIds = [clientIds.first];
                        }
                        if (value == TransactionType.expense &&
                            categoryId == null) {
                          categoryId = model.preferredCategoryId();
                        }
                      }),
                      onAccount: (value) => setState(() {
                        accountTouched = true;
                        accountId = value;
                      }),
                      onCounter: (value) =>
                          setState(() => counterAccountId = value),
                      onCategory: (value) => setState(() {
                        categoryTouched = true;
                        categoryId = value;
                      }),
                      onDate: _pickDate,
                    ),
                    const SizedBox(height: 8),
                    TransactionTagsSection(
                      type: type,
                      readOnly: readOnly,
                      merchant: merchant,
                      selectedTagIds: tagIds,
                      tags: model.tags,
                      model: model,
                      onMerchantChanged: () => setState(() {}),
                      onTagIdsChanged: (value) => setState(() => tagIds = value),
                    ),
                    if (invalid && failure != null)
                      Text(
                        transactionError(s, failure),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else if (invalid)
                      Text(
                        s.transactionInvalid,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (model.needsReload) Text(s.transactionReloadRequired),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            _actions(s, model, readOnly),
          ],
        );
      },
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
