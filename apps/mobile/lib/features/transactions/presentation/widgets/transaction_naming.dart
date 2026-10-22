import 'package:flutter/widgets.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../../tags/domain/tag.dart';
import '../../../wallets/domain/wallet.dart';
import '../../domain/transaction.dart';

/// How one transaction reads in a list. Title: store, else the category
/// (transfer: note, else "Chuyển ví"). Second line: "category · wallet", or
/// "wallet · “note”" when the title already is the category; transfers show
/// "From → To".
class TransactionLabel {
  const TransactionLabel({
    required this.icon,
    required this.title,
    required this.detail,
    required this.category,
    required this.minor,
    required this.currency,
    required this.tone,
    required this.tags,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String category;
  final BigInt minor;
  final String currency;
  final MoneyTone tone;
  final List<String> tags;
}

class TransactionNaming {
  TransactionNaming(
    this.s, {
    required List<FinanceCategory> categories,
    required List<Wallet> wallets,
    List<Tag> tags = const [],
  }) : _categories = {for (final c in categories) c.id: c},
       _wallets = {for (final w in wallets) w.id: w.draft.name},
       _tags = {for (final t in tags) t.id: t.name};

  final S s;
  final Map<String, FinanceCategory> _categories;
  final Map<String, String> _wallets;
  final Map<String, String> _tags;

  String wallet(String id) => _wallets[id] ?? '';
  String? categoryName(String? id) => _categories[id]?.name;

  static MoneyTone tone(TransactionType? type) => switch (type) {
    TransactionType.income => MoneyTone.income,
    TransactionType.transfer => MoneyTone.transfer,
    _ => MoneyTone.expense,
  };

  IconData icon(TransactionType? type, String? categoryId) =>
      type == TransactionType.transfer
      ? categoryIcon('transfer')
      : categoryIcon(_categories[categoryId]?.iconToken);

  String kind(TransactionType type) => switch (type) {
    TransactionType.expense => s.txKindExpense,
    TransactionType.income => s.txKindIncome,
    TransactionType.transfer => s.txKindTransfer,
  };

  TransactionLabel label(TransactionBundle row) {
    final first = row.legs.first;
    final notes = _clean(row.notes);
    final merchant = _clean(row.merchant);
    final category = row.type == TransactionType.transfer
        ? s.txTransferTitle
        : categoryName(row.categoryId) ?? s.homeUncategorized;
    final String title;
    final String detail;
    if (row.type == TransactionType.transfer) {
      title = notes ?? s.txTransferTitle;
      final to = row.legs.length == 2 ? wallet(row.legs.last.accountId) : '';
      detail = [
        wallet(first.accountId),
        to,
      ].where((p) => p.isNotEmpty).join(' → ');
    } else if (merchant != null) {
      title = merchant;
      detail = _join([category, wallet(first.accountId)]);
    } else {
      title = category;
      detail = _join([wallet(first.accountId), if (notes != null) '“$notes”']);
    }
    return TransactionLabel(
      icon: icon(row.type, row.categoryId),
      title: title,
      detail: detail,
      category: category,
      minor: first.amountMinor.abs(),
      currency: first.currencyCode,
      tone: tone(row.type),
      tags: [
        for (final id in row.tagIds)
          if (_tags[id] != null) _tags[id]!,
      ],
    );
  }

  static String? _clean(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _join(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join(' · ');
}
