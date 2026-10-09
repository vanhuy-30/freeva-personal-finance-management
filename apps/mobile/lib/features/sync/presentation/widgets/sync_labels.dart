import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../transactions/domain/transaction.dart';
import '../../domain/sync_item.dart';

String syncItemLabel(S s, SyncQueueItem item) {
  final action = switch (item.action) {
    SyncAction.delete => s.syncDelete,
    SyncAction.restore => s.syncRestore,
    SyncAction.create || SyncAction.update => switch (item.type) {
      TransactionType.income => s.transactionIncome,
      TransactionType.expense => s.transactionExpense,
      TransactionType.transfer => s.transactionTransfer,
      null => s.syncChange,
    },
  };
  final date = item.occurredOn;
  if (date == null || date.isEmpty) return action;
  return s.syncItem(action, date);
}
