import 'package:flutter/widgets.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/money_text.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../categories/domain/finance_category.dart';
import '../../../categories/presentation/widgets/category_badge.dart';
import '../../../sync/domain/sync_item.dart';
import '../../../transactions/domain/transaction.dart';
import '../../../transactions/presentation/widgets/transaction_naming.dart';
import '../../../wallets/domain/wallet.dart';

/// What one "Gần đây" row shows, built from a server transaction or from a
/// transaction still queued on this device.
class RecentRowData {
  const RecentRowData({
    required this.icon,
    required this.title,
    required this.detail,
    required this.minor,
    required this.currency,
    required this.tone,
    this.bundle,
  });

  final IconData icon;
  final String title;
  final String detail;
  final BigInt minor;
  final String currency;
  final MoneyTone tone;

  /// Server transaction; null while queued on this device.
  final TransactionBundle? bundle;
}

class RecentRowNames {
  RecentRowNames(this.s, List<FinanceCategory> categories, List<Wallet> wallets)
    : _categories = {for (final c in categories) c.id: c},
      _wallets = {for (final w in wallets) w.id: w.draft.name},
      _naming = TransactionNaming(s, categories: categories, wallets: wallets);

  final TransactionNaming _naming;

  final S s;
  final Map<String, FinanceCategory> _categories;
  final Map<String, String> _wallets;

  MoneyTone tone(TransactionType? type) => switch (type) {
    TransactionType.income => MoneyTone.income,
    TransactionType.transfer => MoneyTone.transfer,
    _ => MoneyTone.expense,
  };

  /// Store or note first; else the category name.
  String title(String? merchant, String? notes, String category) {
    for (final value in [merchant, notes]) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return category;
  }

  String category(TransactionType? type, String? id) {
    if (type == TransactionType.transfer) return s.homeQuickTransfer;
    return _categories[id]?.name ?? s.homeUncategorized;
  }

  String wallet(String id) => _wallets[id] ?? '';

  /// Same naming as the transaction list.
  RecentRowData fromBundle(TransactionBundle row) {
    final label = _naming.label(row);
    return RecentRowData(
      icon: label.icon,
      title: label.title,
      detail: label.detail,
      minor: label.minor,
      currency: label.currency,
      tone: label.tone,
      bundle: row,
    );
  }

  RecentRowData fromQueued(SyncQueueItem item, String pendingLabel) {
    final cat = category(item.type, item.categoryId);
    final leg = item.legs.isEmpty ? null : item.legs.first;
    return RecentRowData(
      icon: _icon(item.type, item.categoryId),
      title: title(item.merchant, item.notes, cat),
      detail: pendingLabel,
      minor: BigInt.tryParse(leg?.amountMinor ?? '')?.abs() ?? BigInt.zero,
      currency: leg?.currencyCode ?? '',
      tone: tone(item.type),
    );
  }

  IconData _icon(TransactionType? type, String? categoryId) =>
      type == TransactionType.transfer
      ? categoryIcon('transfer')
      : categoryIcon(_categories[categoryId]?.iconToken);
}

/// Spoken form for screen readers: "trừ 65.000 đồng, Phở Thìn, Ăn uống · Tiền mặt".
String spoken(S s, RecentRowData row, int digits, String locale) {
  final amount = formatMoneyText(row.minor, digits, locale);
  final currency = row.currency == 'VND' ? s.homeSpokenVnd : row.currency;
  final signed = switch (row.tone) {
    MoneyTone.income => s.homeSpokenIncome(amount, currency),
    MoneyTone.expense => s.homeSpokenExpense(amount, currency),
    _ => '$amount $currency',
  };
  return s.homeSpokenRow(signed, row.title, row.detail);
}
