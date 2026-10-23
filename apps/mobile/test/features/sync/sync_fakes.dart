import 'package:mobile/features/sync/domain/sync_item.dart';
import 'package:mobile/features/sync/presentation/viewmodels/sync_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';

/// Sync view model with everything set directly, for screen tests.
class FixedSync extends SyncViewModel {
  FixedSync(this.items);

  @override
  List<SyncQueueItem> items;
  @override
  List<SyncQueueItem> get attention => [
    for (final i in items)
      if (i.status != SyncItemStatus.pending) i,
  ];
  @override
  List<SyncQueueItem> get waiting => [
    for (final i in items)
      if (i.status == SyncItemStatus.pending) i,
  ];
  @override
  SyncLink link = SyncLink.ok;
  @override
  DateTime? lastSyncedAt;
  @override
  bool syncing = false;
  @override
  bool schemaMismatch = false;
  @override
  SyncDuplicate? duplicate;
  @override
  void dismissDuplicate() {
    duplicate = null;
    notifyListeners();
  }

  final kept = <String>[];
  @override
  Future<void> keepLocal(String opId) async => kept.add(opId);
  @override
  int appliedEpoch = 0;
  int flushes = 0;
  final retried = <String>[];

  @override
  Future<void> acknowledge({String? clientId, String? serverId}) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<void> discard(String opId) async {
    items = items.where((item) => item.opId != opId).toList();
    notifyListeners();
  }

  @override
  Future<void> retry(String opId) async => retried.add(opId);
  @override
  Future<void> enqueue(SyncMutation mutation) async {}
  @override
  Future<void> flush() async => flushes++;
  @override
  void onResume() {}
}

SyncQueueItem syncItem(
  String opId, {
  SyncItemStatus status = SyncItemStatus.pending,
  SyncReason? reason,
  SyncAction action = SyncAction.create,
  String? serverId,
  int? amount = -55000,
  String merchant = 'Highlands',
}) => SyncQueueItem(
  opId: opId,
  clientId: '11111111-1111-4111-8111-111111111111',
  serverId: serverId,
  action: action,
  type: TransactionType.expense,
  occurredOn: '2026-10-22',
  merchant: merchant,
  legs: amount == null
      ? const []
      : [
          SyncLeg(
            clientId: '22222222-2222-4222-8222-222222222222',
            accountId: 'cash',
            currencyCode: 'VND',
            amountMinor: '$amount',
          ),
        ],
  // Local time on purpose: screens print it as is, whatever the time zone.
  createdAt: DateTime(2026, 10, 22, 9, 12),
  retryCount: 0,
  status: status,
  review: false,
  reason: reason,
);
