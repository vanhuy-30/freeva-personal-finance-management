import '../../transactions/domain/transaction.dart';

const int syncSchemaVersion = 1;
const int syncBatchLimit = 50;

enum SyncAction { create, update, delete, restore }

enum SyncItemStatus { pending, conflict, failed }

/// The server's copy of a transaction at the time of a conflict, kept so the
/// person can compare it with their own change.
class SyncServerCopy {
  const SyncServerCopy({
    required this.id,
    required this.version,
    required this.occurredOn,
    required this.amountMinor,
    required this.currencyCode,
    this.occurredTime,
    this.categoryId,
    this.notes,
    this.merchant,
    this.updatedAt,
  });

  final String id;
  final int version;
  final String occurredOn;
  final String? occurredTime;

  /// Signed integer string, as the server sends it.
  final String amountMinor;
  final String currencyCode;
  final String? categoryId;
  final String? notes;
  final String? merchant;
  final DateTime? updatedAt;
}

/// A queued create that the server accepted but found alike to an earlier
/// transaction: the new one and the one that was already there.
class SyncDuplicate {
  const SyncDuplicate({required this.newId, required this.existingId});

  final String newId;
  final String existingId;
}

/// Why a change is waiting for the person (shown as one short line).
enum SyncReason {
  /// Someone changed it on another device first.
  changedElsewhere,

  /// The wallet it uses no longer exists.
  walletMissing,

  /// The transaction it edits is gone.
  transactionMissing,

  /// The server refused the data as it is.
  invalid,

  /// Not sent yet for another reason; trying again later may work.
  unavailable,
}

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
    this.occurredTime,
    this.categoryId,
    this.notes,
    this.merchant,
    this.tagIds = const [],
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
  final String? occurredTime;
  final String? categoryId;
  final String? notes;
  final String? merchant;
  final List<String> tagIds;
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
    this.occurredTime,
    this.categoryId,
    this.notes,
    this.merchant,
    this.tagIds = const [],
    this.legs = const [],
    this.rate,
    this.quotedAt,
    this.serverUpdatedAt,
    this.reason,
    this.server,
  });

  final String opId;
  final String clientId;
  final String? serverId;
  final SyncAction action;
  final TransactionType? type;
  final String? occurredOn;
  final String? occurredTime;
  final String? categoryId;
  final String? notes;
  final String? merchant;
  final List<String> tagIds;
  final List<SyncLeg> legs;
  final String? rate;
  final String? quotedAt;
  final int? version;
  final DateTime createdAt;
  final DateTime? serverUpdatedAt;
  final int retryCount;
  final SyncItemStatus status;
  final bool review;

  /// Set once the item needs attention; null while it is just waiting.
  final SyncReason? reason;

  /// Server copy to compare with, set on a conflict when it could be read.
  final SyncServerCopy? server;

  static const Object _keep = Object();

  SyncQueueItem copyWith({
    String? opId,
    String? clientId,
    Object? serverId = _keep,
    SyncAction? action,
    Object? type = _keep,
    Object? occurredOn = _keep,
    Object? occurredTime = _keep,
    Object? categoryId = _keep,
    Object? notes = _keep,
    Object? merchant = _keep,
    List<String>? tagIds,
    List<SyncLeg>? legs,
    Object? rate = _keep,
    Object? quotedAt = _keep,
    Object? version = _keep,
    DateTime? createdAt,
    Object? serverUpdatedAt = _keep,
    int? retryCount,
    SyncItemStatus? status,
    bool? review,
    Object? reason = _keep,
    Object? server = _keep,
  }) {
    return SyncQueueItem(
      opId: opId ?? this.opId,
      clientId: clientId ?? this.clientId,
      serverId: serverId == _keep ? this.serverId : serverId as String?,
      action: action ?? this.action,
      type: type == _keep ? this.type : type as TransactionType?,
      occurredOn: occurredOn == _keep ? this.occurredOn : occurredOn as String?,
      occurredTime: occurredTime == _keep
          ? this.occurredTime
          : occurredTime as String?,
      categoryId: categoryId == _keep ? this.categoryId : categoryId as String?,
      notes: notes == _keep ? this.notes : notes as String?,
      merchant: merchant == _keep ? this.merchant : merchant as String?,
      tagIds: tagIds ?? this.tagIds,
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
      reason: reason == _keep ? this.reason : reason as SyncReason?,
      server: server == _keep ? this.server : server as SyncServerCopy?,
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
    this.errorCode,
    this.server,
    this.transactionId,
    this.duplicateIds = const [],
  });

  final String opId;
  final String status;
  final bool review;
  final bool duplicateHint;
  final DateTime? serverUpdatedAt;

  /// Server code for a conflict or rejection (e.g. `ACCOUNT_NOT_FOUND`).
  final String? errorCode;

  /// The server's copy on a conflict, when it could be read.
  final SyncServerCopy? server;

  /// Id of the transaction this item created or changed, when returned.
  final String? transactionId;

  /// Ids of earlier transactions that look the same as a new one.
  final List<String> duplicateIds;
}
