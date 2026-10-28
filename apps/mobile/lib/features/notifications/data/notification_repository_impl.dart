import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/notification_models.dart';
import '../domain/notification_repository.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._api);

  final AuthorizedApi _api;

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
  }) async {
    final result = await _api.request(method, path, body: body);
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, NotificationPreferences>> preferences() =>
      _request('GET', 'notification-preferences', _preferences);

  @override
  Future<Either<AuthFailure, NotificationPreferences>> putPreferences(
    NotificationPreferencesPatch patch,
  ) => _request(
    'PUT',
    'notification-preferences',
    _preferences,
    body: {
      if (patch.budgetEnabled != null) 'budgetEnabled': patch.budgetEnabled,
      if (patch.goalEnabled != null) 'goalEnabled': patch.goalEnabled,
      if (patch.debtEnabled != null) 'debtEnabled': patch.debtEnabled,
      if (patch.cardEnabled != null) 'cardEnabled': patch.cardEnabled,
      if (patch.recurringEnabled != null)
        'recurringEnabled': patch.recurringEnabled,
      if (patch.monthReviewEnabled != null)
        'monthReviewEnabled': patch.monthReviewEnabled,
      if (patch.insightEnabled != null) 'insightEnabled': patch.insightEnabled,
      if (patch.quietHoursEnabled != null)
        'quietHoursEnabled': patch.quietHoursEnabled,
      if (patch.quietStart != null) 'quietStart': patch.quietStart,
      if (patch.quietEnd != null) 'quietEnd': patch.quietEnd,
      if (patch.version != null) 'version': patch.version,
    },
  );

  @override
  Future<Either<AuthFailure, List<InboxNotification>>> list() => _request(
    'GET',
    'notifications',
    (json) {
      final items = json['items'];
      if (items is! List) throw const FormatException('items');
      return [
        for (final row in items)
          _item(Map<String, dynamic>.from(row as Map)),
      ];
    },
  );

  @override
  Future<Either<AuthFailure, InboxNotification>> markRead(String id) =>
      _request('POST', 'notifications/$id/read', _item);

  @override
  Future<Either<AuthFailure, int>> markAllRead() => _request(
    'POST',
    'notifications/read-all',
    (json) => (json['updated'] as num).toInt(),
  );

  @override
  Future<Either<AuthFailure, int>> evaluate() => _request(
    'POST',
    'notifications/evaluate',
    (json) => (json['created'] as num).toInt(),
  );
}

NotificationPreferences _preferences(Map<String, dynamic> json) {
  final kinds = json['kinds'];
  if (kinds is! List) throw const FormatException('kinds');
  return NotificationPreferences(
    kinds: [
      for (final row in kinds)
        _toggle(Map<String, dynamic>.from(row as Map)),
    ],
    quietHoursEnabled: json['quietHoursEnabled'] as bool,
    quietStart: json['quietStart'] as String,
    quietEnd: json['quietEnd'] as String,
    version: (json['version'] as num).toInt(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

NotificationKindToggle _toggle(Map<String, dynamic> json) {
  final kind = notificationKindFromApi(json['kind'] as String);
  if (kind == null) throw const FormatException('kind');
  return NotificationKindToggle(
    kind: kind,
    enabled: json['enabled'] as bool,
    available: json['available'] as bool,
    managedLocally: json['managedLocally'] as bool,
  );
}

InboxNotification _item(Map<String, dynamic> json) {
  final kind = notificationKindFromApi(json['kind'] as String);
  if (kind == null) throw const FormatException('kind');
  final paramsRaw = json['params'];
  final params = <String, Object>{};
  if (paramsRaw is Map) {
    for (final entry in paramsRaw.entries) {
      final value = entry.value;
      if (value is String || value is num) {
        params['${entry.key}'] = value is num ? value.toInt() : value as Object;
      }
    }
  }
  final readAt = json['readAt'];
  return InboxNotification(
    id: json['id'] as String,
    kind: kind,
    titleKey: json['titleKey'] as String,
    bodyKey: json['bodyKey'] as String,
    params: params,
    createdAt: DateTime.parse(json['createdAt'] as String),
    readAt: readAt == null ? null : DateTime.parse(readAt as String),
  );
}
