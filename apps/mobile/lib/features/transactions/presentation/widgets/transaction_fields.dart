import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_money.dart';
import 'transaction_category_sheet.dart';
import 'transaction_labels.dart';

class TransactionFields extends StatelessWidget {
  const TransactionFields({
    required this.type,
    required this.lockedType,
    required this.readOnly,
    required this.accountId,
    required this.counterAccountId,
    required this.categoryId,
    required this.occurredOn,
    required this.amount,
    required this.notes,
    required this.rate,
    required this.wallets,
    required this.currencies,
    required this.categories,
    required this.recent,
    required this.onType,
    required this.onAccount,
    required this.onCounter,
    required this.onCategory,
    required this.onDate,
    super.key,
  });

  final TransactionType type;
  final bool lockedType;
  final bool readOnly;
  final String? accountId;
  final String? counterAccountId;
  final String? categoryId;
  final String occurredOn;
  final TextEditingController amount;
  final TextEditingController notes;
  final TextEditingController rate;
  final List<Wallet> wallets;
  final List<WalletCurrency> currencies;
  final List<FinanceCategory> categories;
  final List<FinanceCategory> recent;
  final ValueChanged<TransactionType> onType;
  final ValueChanged<String?> onAccount;
  final ValueChanged<String?> onCounter;
  final ValueChanged<String?> onCategory;
  final VoidCallback onDate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final active = wallets.where((wallet) => !wallet.archived).toList();
    final locale = Localizations.localeOf(context).toString();
    final crossCurrency = _crossCurrency(active);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final item in TransactionType.values)
              ChoiceChip(
                label: Text(transactionTypeLabel(s, item)),
                selected: type == item,
                onSelected: lockedType || readOnly ? null : (_) => onType(item),
              ),
          ],
        ),
        _walletPicker(
          s.transactionWallet,
          active,
          accountId,
          readOnly,
          onAccount,
        ),
        if (type == TransactionType.transfer)
          _walletPicker(
            s.transactionDestination,
            active,
            counterAccountId,
            readOnly,
            onCounter,
          ),
        TextField(
          controller: amount,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: s.transactionAmount,
            helperText: s.walletMoneyHint,
          ),
        ),
        if (crossCurrency) ...[
          TextField(
            controller: rate,
            readOnly: readOnly,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: s.transactionRate,
              helperText: s.transactionRateHint,
            ),
          ),
          Text(_destination(active, locale, s)),
        ],
        if (type != TransactionType.transfer) ...[
          Wrap(
            spacing: 8,
            children: [
              for (final category in recent.take(8))
                ChoiceChip(
                  label: Text(category.name),
                  selected: categoryId == category.id,
                  onSelected: readOnly
                      ? null
                      : (_) => onCategory(
                          categoryId == category.id ? null : category.id,
                        ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: readOnly
                  ? null
                  : () async {
                      final picked = await pickCategory(context, categories);
                      if (picked != null && context.mounted) onCategory(picked);
                    },
              child: Text(s.transactionAllCategories),
            ),
          ),
          Text(_categoryName(s)),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: readOnly ? null : onDate,
            child: Text('${s.transactionDate}: $occurredOn'),
          ),
        ),
        TextField(
          controller: notes,
          readOnly: readOnly,
          maxLines: 3,
          maxLength: 2000,
          decoration: InputDecoration(labelText: s.transactionNotes),
        ),
      ],
    );
  }

  Widget _walletPicker(
    String label,
    List<Wallet> active,
    String? selected,
    bool readOnly,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String>(
    isExpanded: true,
    initialValue: active.any((wallet) => wallet.id == selected)
        ? selected
        : null,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final wallet in active)
        DropdownMenuItem(value: wallet.id, child: Text(wallet.draft.name)),
    ],
    onChanged: readOnly ? null : onChanged,
  );

  bool _crossCurrency(List<Wallet> active) {
    if (type != TransactionType.transfer) return false;
    final source = _wallet(active, accountId);
    final destination = _wallet(active, counterAccountId);
    return source != null &&
        destination != null &&
        source.draft.currency != destination.draft.currency;
  }

  String _destination(List<Wallet> active, String locale, S s) {
    final source = _wallet(active, accountId);
    final destination = _wallet(active, counterAccountId);
    if (source == null || destination == null) return '';
    final sourceDigits = _digits(source.draft.currency);
    final parsed = parseMoneyText(amount.text, sourceDigits, locale);
    if (parsed == null || parsed <= BigInt.zero) return '';
    final converted = convertedMinor(
      -parsed,
      rate.text,
      sourceDigits,
      _digits(destination.draft.currency),
    );
    if (converted == null) return s.transactionInvalid;
    return '${s.transactionDestination}: ${formatMoneyText(converted, _digits(destination.draft.currency), locale)} ${destination.draft.currency}';
  }

  Wallet? _wallet(List<Wallet> active, String? id) {
    for (final wallet in active) {
      if (wallet.id == id) return wallet;
    }
    return null;
  }

  int _digits(String code) {
    for (final currency in currencies) {
      if (currency.code == code) return currency.minorDigits;
    }
    return 0;
  }

  String _categoryName(S s) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return s.transactionCategory;
  }
}
