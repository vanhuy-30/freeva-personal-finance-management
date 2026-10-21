import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../settings/presentation/widgets/masked_amount.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../tags/domain/tag.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';
import '../viewmodels/transaction_view_model.dart';
import 'transaction_labels.dart';

class TransactionList extends StatelessWidget {
  const TransactionList({required this.model, required this.onOpen, super.key});
  final TransactionViewModel model;
  final ValueChanged<TransactionBundle> onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final rows = model.rows;
    if (rows.isEmpty) {
      return Center(
        child: Text(
          model.deleted ? s.transactionDeletedEmpty : s.transactionEmpty,
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return ListView.builder(
      itemCount: rows.length + (model.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: model.busy ? null : model.loadMore,
              child: Text(s.transactionLoadMore),
            ),
          );
        }
        final row = rows[index];
        final source = row.legs.first;
        final currency = _digits(model, source.currencyCode);
        final amount = formatMoneyText(source.amountMinor, currency, locale);
        return ListTile(
          title: Text(_label(s, model.categories, row)),
          subtitle: Text(
            _subtitle(
              date: _date(source.occurredOn, locale),
              wallet: _wallet(model.wallets, source.accountId),
              merchant: source.merchant,
              tags: _tagNames(model.tags, source.tagIds),
            ),
          ),
          trailing: MaskedAmount(
            shown: '$amount ${source.currencyCode}',
            hidden: '${s.balanceHiddenMask} ${source.currencyCode}',
          ),
          onTap: () => onOpen(row),
        );
      },
    );
  }
}

String _subtitle({
  required String date,
  required String wallet,
  required String? merchant,
  required List<String> tags,
}) {
  final parts = <String>[date, wallet];
  final trimmed = merchant?.trim();
  if (trimmed != null && trimmed.isNotEmpty) parts.add(trimmed);
  if (tags.isNotEmpty) parts.add(tags.join(', '));
  return parts.join(' · ');
}

List<String> _tagNames(List<Tag> tags, List<String> ids) {
  final byId = {for (final tag in tags) tag.id: tag.name};
  return [
    for (final id in ids)
      if (byId.containsKey(id)) byId[id]!,
  ];
}

int _digits(TransactionViewModel model, String code) {
  for (final currency in model.currencies) {
    if (currency.code == code) return currency.minorDigits;
  }
  return 0;
}

String _wallet(List<Wallet> wallets, String id) {
  for (final wallet in wallets) {
    if (wallet.id == id) return wallet.draft.name;
  }
  return id;
}

String _label(S s, List<FinanceCategory> categories, TransactionBundle row) {
  if (row.type == TransactionType.transfer) {
    return s.transactionTransfer;
  }
  for (final category in categories) {
    if (category.id == row.categoryId) return category.name;
  }
  return transactionTypeLabel(s, row.type);
}

String _date(String occurredOn, String locale) {
  final parts = occurredOn.split('-');
  if (parts.length != 3) return occurredOn;
  return DateFormat.yMMMd(locale).format(
    DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
  );
}
