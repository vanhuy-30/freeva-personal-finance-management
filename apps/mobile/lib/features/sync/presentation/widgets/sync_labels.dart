import 'package:intl/intl.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/sync_item.dart';

String syncActionLabel(S s, SyncAction action) => switch (action) {
  SyncAction.create => s.syncActionAdd,
  SyncAction.update => s.syncActionEdit,
  SyncAction.delete => s.syncActionDelete,
  SyncAction.restore => s.syncActionRestore,
};

String syncReasonLabel(S s, SyncReason? reason) => switch (reason) {
  SyncReason.changedElsewhere => s.syncReasonChanged,
  SyncReason.walletMissing => s.syncReasonWallet,
  SyncReason.transactionMissing => s.syncReasonMissing,
  SyncReason.invalid => s.syncReasonInvalid,
  SyncReason.categoryKind => s.syncReasonCategoryKind,
  SyncReason.unavailable || null => s.syncReasonOther,
};

/// "09:30" for the item's own time.
String syncClock(DateTime at, String locale) =>
    DateFormat('HH:mm', locale).format(at.toLocal());

/// "hôm nay 09:30", or "21/10 09:30" on another day.
String syncWhen(S s, DateTime at, DateTime now, String locale) {
  final local = at.toLocal();
  final time = DateFormat('HH:mm', locale).format(local);
  final today =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  return today
      ? s.syncToday(time)
      : s.syncOnDay(DateFormat('dd/MM', locale).format(local), time);
}

/// "Lần cuối 09:30 hôm nay", or "Lần cuối 21/10 09:30" on another day.
String syncLast(S s, DateTime at, DateTime now, String locale) {
  final local = at.toLocal();
  final time = DateFormat('HH:mm', locale).format(local);
  return _sameDay(local, now)
      ? s.syncLastToday(time)
      : s.syncLastTime(
          s.syncOnDay(DateFormat('dd/MM', locale).format(local), time),
        );
}

/// "12:45" today, "21/10 12:45" on another day (compare cards).
String syncAt(S s, DateTime at, DateTime now, String locale) {
  final local = at.toLocal();
  final time = DateFormat('HH:mm', locale).format(local);
  return _sameDay(local, now)
      ? time
      : s.syncOnDay(DateFormat('dd/MM', locale).format(local), time);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Whether trying again can help: only when the reason is not about the data.
bool syncCanRetry(SyncQueueItem item) =>
    item.status == SyncItemStatus.failed &&
    (item.reason == null || item.reason == SyncReason.unavailable);
