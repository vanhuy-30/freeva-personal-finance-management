import 'package:flutter/widgets.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/money_display.dart';
import '../../../home/presentation/widgets/recent_row_data.dart';
import '../../../transactions/presentation/viewmodels/transaction_view_model.dart';
import '../../domain/sync_item.dart';

/// What the Đồng bộ screen shows for one queued change.
class SyncItemView {
  const SyncItemView({
    required this.icon,
    required this.title,
    required this.tone,
    required this.currency,
    required this.minorDigits,
    this.minor,
  });

  final IconData icon;
  final String title;
  final MoneyTone tone;
  final String currency;
  final int minorDigits;

  /// Null when the change carries no amount and the transaction is not loaded.
  final BigInt? minor;
}

/// Names and amount for [item]. Deletes and restores carry no amount, so the
/// loaded transaction with the same id fills it in when there is one.
SyncItemView syncItemView(S s, SyncQueueItem item, TransactionViewModel tx) {
  final names = RecentRowNames(s, tx.categories, tx.wallets);
  int digits(String code) =>
      tx.currencies
          .where((c) => c.code == code)
          .map((c) => c.minorDigits)
          .firstOrNull ??
      0;
  if (item.legs.isNotEmpty) {
    final row = names.fromQueued(item, '');
    return SyncItemView(
      icon: row.icon,
      title: row.title,
      tone: row.tone,
      currency: row.currency,
      minorDigits: digits(row.currency),
      minor: row.minor,
    );
  }
  final bundle = [
    for (final row in tx.rows)
      if (item.serverId != null && row.id == item.serverId) row,
  ].firstOrNull;
  if (bundle != null) {
    final row = names.fromBundle(bundle);
    return SyncItemView(
      icon: row.icon,
      title: row.title,
      tone: row.tone,
      currency: row.currency,
      minorDigits: digits(row.currency),
      minor: row.minor,
    );
  }
  final row = names.fromQueued(item, '');
  return SyncItemView(
    icon: row.icon,
    title: row.title,
    tone: row.tone,
    currency: '',
    minorDigits: 0,
  );
}
