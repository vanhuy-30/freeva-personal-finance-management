import '../../transactions/domain/transaction.dart';

const int syncSchemaVersion = 1;
const int syncBatchLimit = 50;

enum SyncAction { create, update, delete, restore }

enum SyncItemStatus { pending, conflict, failed }

class SyncLeg {
  const SyncLeg({
    required this.clientId,
    required this.accountId,
    required this.currencyCode,
    required this.amountMinor,
  });

  final String clientId;
  final String accountId;
  final String currencyCode;
  final String amountMinor;
}

class SyncMutation {
  const SyncMutation({
    required this.action,
    required this.clientId,
    this.serverId,
    this.version,
    this.type,
    this.occurredOn,
    this.categoryId,
    this.notes,
    this.legs = const [],
    this.rate,
    this.quotedAt,
  });

  final SyncAction action;
  final String clientId;
  final String? serverId;
  final int? version;
  final TransactionType? type;
  final String? occurredOn;
  final String? categoryId;
  final String? notes;
  final List<SyncLeg> legs;
  final String? rate;
  final String? quotedAt;
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.opId,
    required this.clientId,
    required this.action,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    required this.review,
    this.serverId,
    this.version,
    this.type,
    this.occurredOn,
    this.categoryId,
    this.notes,
    this.legs = const [],
    this.rate,
    this.quotedAt,
    this.serverUpdatedAt,
  });

  final String opId;
  final String clientId;
  final String? serverId;
  final SyncAction action;
  final TransactionType? type;
  final String? occurredOn;
  final String? categoryId;
  final String? notes;
  final List<SyncLeg> legs;
  final String? rate;
  final String? quotedAt;
  final int? version;
  final DateTime createdAt;
  final DateTime? serverUpdatedAt;
  final int retryCount;
  final SyncItemStatus status;
  final bool review;

  static const Object _keep = Object();

  SyncQueueItem copyWith({
    String? opId,
    String? clientId,
    Object? serverId = _keep,
    SyncAction? action,
    Object? type = _keep,
    Object? occurredOn = _keep,
    Object? categoryId = _keep,
    Object? notes = _keep,
    List<SyncLeg>? legs,
    Object? rate = _keep,
    Object? quotedAt = _keep,
    Object? version = _keep,
    DateTime? createdAt,
    Object? serverUpdatedAt = _keep,
    int? retryCount,
    SyncItemStatus? status,
    bool? review,
  }) {
    return SyncQueueItem(
      opId: opId ?? this.opId,
      clientId: clientId ?? this.clientId,
      serverId: serverId == _keep ? this.serverId : serverId as String?,
      action: action ?? this.action,
      type: type == _keep ? this.type : type as TransactionType?,
      occurredOn: occurredOn == _keep ? this.occurredOn : occurredOn as String?,
      categoryId: categoryId == _keep ? this.categoryId : categoryId as String?,
      notes: notes == _keep ? this.notes : notes as String?,
      legs: legs ?? this.legs,
      rate: rate == _keep ? this.rate : rate as String?,
      quotedAt: quotedAt == _keep ? this.quotedAt : quotedAt as String?,
      version: version == _keep ? this.version : version as int?,
      createdAt: createdAt ?? this.createdAt,
      serverUpdatedAt: serverUpdatedAt == _keep
          ? this.serverUpdatedAt
          : serverUpdatedAt as DateTime?,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      review: review ?? this.review,
    );
  }
}

class SyncItemResult {
  const SyncItemResult({
    required this.opId,
    required this.status,
    required this.review,
    required this.duplicateHint,
    this.serverUpdatedAt,
  });

  final String opId;
  final String status;
  final bool review;
  final bool duplicateHint;
  final DateTime? serverUpdatedAt;
}
