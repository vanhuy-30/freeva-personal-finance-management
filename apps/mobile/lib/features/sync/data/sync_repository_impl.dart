import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/logging/app_logger.dart';
import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../../transactions/domain/transaction.dart';
import '../domain/sync_item.dart';
import '../domain/sync_repository.dart';
import 'sync_queue_vault.dart';

@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._api, this._vault, this._logger);

  final AuthorizedApi _api;
  final SyncQueueVault _vault;
  final AppLogger _logger;

  @override
  Future<List<SyncQueueItem>> read() async {
    final raw = await _vault.read();
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const [];
      final items = decoded['items'];
      if (items is! List) return const [];
      return [for (final item in items) _item(item as Map<String, dynamic>)];
    } catch (_) {
      _logger.error('sync queue unreadable');
      return const [];
    }
  }

  @override
  Future<void> write(List<SyncQueueItem> items) async {
    if (items.isEmpty) {
      await _vault.delete();
      return;
    }
    await _vault.write(
      jsonEncode({
        'items': [for (final item in items) _json(item)],
      }),
    );
  }

  @override
  Future<Either<AuthFailure, List<SyncItemResult>>> submit(
    List<SyncQueueItem> batch,
  ) async {
    final result = await _api.request(
      'POST',
      'sync',
      body: {
        'schemaVersion': syncSchemaVersion,
        'operations': [for (final item in batch) _operation(item)],
      },
    );
    return result.fold(left, (json) {
      try {
        final results = json['results'];
        if (results is! List) {
          return left(const AuthFailure(AuthError.unavailable));
        }
        return right([
          for (final item in results) _result(item as Map<String, dynamic>),
        ]);
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  Map<String, dynamic> _operation(SyncQueueItem item) {
    switch (item.action) {
      case SyncAction.create:
        return {'opId': item.opId, 'action': 'create', 'body': _body(item)};
      case SyncAction.update:
        return {
          'opId': item.opId,
          'action': 'update',
          'id': item.serverId,
          'body': _body(item, version: item.version),
        };
      case SyncAction.delete:
        return {
          'opId': item.opId,
          'action': 'delete',
          'id': item.serverId,
          'version': item.version,
        };
      case SyncAction.restore:
        return {
          'opId': item.opId,
          'action': 'update',
          'id': item.serverId,
          'body': {'version': item.version, 'deleted': false},
        };
    }
  }

  Map<String, dynamic> _body(SyncQueueItem item, {int? version}) => {
    if (version == null) 'type': item.type?.name,
    if (version != null) 'version': version,
    'occurredOn': item.occurredOn,
    'categoryId': item.categoryId,
    'notes': item.notes,
    'legs': [
      for (final leg in item.legs)
        {
          'clientId': leg.clientId,
          'accountId': leg.accountId,
          'currencyCode': leg.currencyCode,
          'amountMinor': leg.amountMinor,
        },
    ],
    'fx': item.rate == null
        ? null
        : {'rate': item.rate, 'quotedAt': item.quotedAt},
  };
}

Map<String, dynamic> _json(SyncQueueItem item) => {
  'opId': item.opId,
  'clientId': item.clientId,
  'serverId': item.serverId,
  'action': item.action.name,
  'type': item.type?.name,
  'occurredOn': item.occurredOn,
  'categoryId': item.categoryId,
  'notes': item.notes,
  'legs': [
    for (final leg in item.legs)
      {
        'clientId': leg.clientId,
        'accountId': leg.accountId,
        'currencyCode': leg.currencyCode,
        'amountMinor': leg.amountMinor,
      },
  ],
  'rate': item.rate,
  'quotedAt': item.quotedAt,
  'version': item.version,
  'createdAt': item.createdAt.toUtc().toIso8601String(),
  'serverUpdatedAt': item.serverUpdatedAt?.toUtc().toIso8601String(),
  'retryCount': item.retryCount,
  'status': item.status.name,
  'review': item.review,
};

SyncQueueItem _item(Map<String, dynamic> json) {
  final legs = json['legs'];
  return SyncQueueItem(
    opId: json['opId'] as String,
    clientId: json['clientId'] as String,
    serverId: json['serverId'] as String?,
    action: SyncAction.values.byName(json['action'] as String),
    type: json['type'] == null
        ? null
        : TransactionType.values.byName(json['type'] as String),
    occurredOn: json['occurredOn'] as String?,
    categoryId: json['categoryId'] as String?,
    notes: json['notes'] as String?,
    legs: legs is List
        ? [
            for (final leg in legs.cast<Map<String, dynamic>>())
              SyncLeg(
                clientId: leg['clientId'] as String,
                accountId: leg['accountId'] as String,
                currencyCode: leg['currencyCode'] as String,
                amountMinor: leg['amountMinor'] as String,
              ),
          ]
        : const [],
    rate: json['rate'] as String?,
    quotedAt: json['quotedAt'] as String?,
    version: json['version'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    serverUpdatedAt: json['serverUpdatedAt'] == null
        ? null
        : DateTime.parse(json['serverUpdatedAt'] as String).toUtc(),
    retryCount: json['retryCount'] as int? ?? 0,
    status: SyncItemStatus.values.byName(json['status'] as String),
    review: json['review'] == true,
  );
}

SyncItemResult _result(Map<String, dynamic> json) {
  DateTime? updated;
  final transaction = json['transaction'];
  if (transaction is Map<String, dynamic>) {
    final legs = transaction['legs'];
    if (legs is List && legs.isNotEmpty && legs.first is Map<String, dynamic>) {
      final stamp = legs.first['updatedAt'];
      if (stamp is String) updated = DateTime.tryParse(stamp)?.toUtc();
    }
  }
  final duplicates = json['duplicates'];
  return SyncItemResult(
    opId: json['opId'] as String,
    status: json['status'] as String,
    review: json['review'] == true,
    duplicateHint: duplicates is List && duplicates.isNotEmpty,
    serverUpdatedAt: updated,
  );
}
