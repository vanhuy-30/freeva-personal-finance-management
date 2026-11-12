import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/goal.dart';
import '../domain/goal_forecast.dart';
import '../domain/goal_repository.dart';

@LazySingleton(as: GoalRepository)
class GoalRepositoryImpl implements GoalRepository {
  GoalRepositoryImpl(this._api);
  final AuthorizedApi _api;

  BigInt? _money(Object? value) =>
      value == null ? null : BigInt.parse(value as String);

  Goal _parse(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    kind: json['kind'] as String,
    name: json['name'] as String,
    currencyCode: json['currencyCode'] as String,
    targetMinor: BigInt.parse(json['targetMinor'] as String),
    currentMinor: BigInt.parse(json['currentMinor'] as String),
    remainingMinor: BigInt.parse(json['remainingMinor'] as String),
    percentBps: json['percentBps'] as int,
    status: GoalStatus.values.byName(json['status'] as String),
    accountId: json['accountId'] as String,
    icon: json['icon'] as String,
    colorToken: json['colorToken'] as String?,
    targetDate: json['targetDate'] as String?,
    monthsLeft: json['monthsLeft'] as int?,
    requiredPerMonthMinor: _money(json['requiredPerMonthMinor']),
    monthlyContributionMinor: _money(json['monthlyContributionMinor']),
    incomeShareBps: json['incomeShareBps'] as int?,
    archived: json['archivedAt'] != null,
    version: json['version'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Future<Either<AuthFailure, T>> _request<T>(
    String method,
    String path,
    T Function(Map<String, dynamic>) parse, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final result = await _api.request(
      method,
      path,
      body: body,
      headers: headers,
    );
    return result.fold(left, (json) {
      try {
        return right(parse(json));
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    });
  }

  @override
  Future<Either<AuthFailure, List<Goal>>> list({
    bool includeArchived = false,
  }) => _request(
    'GET',
    includeArchived ? 'goals?includeArchived=true' : 'goals',
    (json) => List.unmodifiable(
      (json['items'] as List).map((e) => _parse(e as Map<String, dynamic>)),
    ),
  );

  @override
  Future<Either<AuthFailure, Goal>> find(String id) =>
      _request('GET', 'goals/$id', _parse);

  @override
  Future<Either<AuthFailure, Goal>> create(GoalDraft draft) => _request(
    'POST',
    'goals',
    _parse,
    body: {
      'clientId': draft.clientId,
      'kind': draft.kind,
      'name': draft.name.trim(),
      'targetMinor': draft.targetMinor.toString(),
      'accountId': draft.accountId,
      if (draft.currentMinor != null)
        'currentMinor': draft.currentMinor.toString(),
      if (draft.targetDate != null) 'targetDate': draft.targetDate,
      if (draft.icon != null) 'icon': draft.icon,
      if (draft.colorToken != null) 'colorToken': draft.colorToken,
    },
    headers: {'Idempotency-Key': draft.clientId},
  );

  @override
  Future<Either<AuthFailure, Goal>> update(
    Goal goal, {
    String? kind,
    String? name,
    BigInt? targetMinor,
    String? targetDate,
    bool clearTargetDate = false,
    String? icon,
    String? colorToken,
  }) => _request(
    'PATCH',
    'goals/${goal.id}',
    _parse,
    body: {
      'version': goal.version,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (targetMinor != null) 'targetMinor': targetMinor.toString(),
      if (clearTargetDate) 'targetDate': null,
      if (!clearTargetDate && targetDate != null) 'targetDate': targetDate,
      if (icon != null) 'icon': icon,
      if (colorToken != null) 'colorToken': colorToken,
    },
  );

  @override
  Future<Either<AuthFailure, Unit>> archive(Goal goal) => _request(
    'DELETE',
    'goals/${goal.id}?version=${goal.version}',
    (_) => unit,
  );

  Map<String, dynamic> _moveBody(GoalMove move) => {
    'clientId': move.clientId,
    'amountMinor': move.amountMinor.toString(),
    'occurredOn': move.occurredOn,
    if (move.accountId != null) 'accountId': move.accountId,
  };

  @override
  Future<Either<AuthFailure, Goal>> contribute(Goal goal, GoalMove move) =>
      _request(
        'POST',
        'goals/${goal.id}/contribute',
        _parse,
        body: _moveBody(move),
        headers: {'Idempotency-Key': move.clientId},
      );

  @override
  Future<Either<AuthFailure, Goal>> withdraw(Goal goal, GoalMove move) =>
      _request(
        'POST',
        'goals/${goal.id}/withdraw',
        _parse,
        body: _moveBody(move),
        headers: {'Idempotency-Key': move.clientId},
      );

  @override
  Future<Either<AuthFailure, Goal>> adjust(Goal goal, BigInt currentMinor) =>
      _request(
        'POST',
        'goals/${goal.id}/adjust',
        _parse,
        body: {
          'currentMinor': currentMinor.toString(),
          'version': goal.version,
        },
      );

  @override
  Future<Either<AuthFailure, List<GoalEntry>>> entries(String id) => _request(
    'GET',
    'goals/$id/entries',
    (json) => List.unmodifiable(
      (json['items'] as List).map((raw) {
        final e = raw as Map<String, dynamic>;
        return GoalEntry(
          id: e['id'] as String,
          kind: GoalEntryKind.values.byName(e['kind'] as String),
          amountMinor: _money(e['amountMinor']),
          transfer: e['transfer'] as bool,
          occurredOn: e['occurredOn'] as String,
        );
      }),
    ),
  );

  @override
  Future<Either<AuthFailure, GoalPreview>> preview({
    required String currency,
    required BigInt targetMinor,
    required String targetDate,
  }) => _request(
    'POST',
    'goals/preview',
    (json) => GoalPreview(
      monthsLeft: json['monthsLeft'] as int,
      requiredPerMonthMinor: _money(json['requiredPerMonthMinor']),
      incomeShareBps: json['incomeShareBps'] as int?,
    ),
    body: {
      'currencyCode': currency,
      'targetMinor': targetMinor.toString(),
      'targetDate': targetDate,
    },
  );

  @override
  Future<Either<AuthFailure, List<GoalPreset>>> presets() => _request(
    'GET',
    'goals/presets',
    (json) => List.unmodifiable(
      (json['items'] as List).map((raw) {
        final e = raw as Map<String, dynamic>;
        return GoalPreset(
          kind: e['kind'] as String,
          icon: e['icon'] as String,
          colorToken: e['colorToken'] as String?,
        );
      }),
    ),
  );

  @override
  Future<Either<AuthFailure, GoalForecast?>> forecast(String id) =>
      _request('GET', 'goals/$id/forecast', parseForecast);

  /// `GET /goals/{id}/forecast`; null when forecasts are off.
  static GoalForecast? parseForecast(Map<String, dynamic> json) {
    final raw = json['forecast'] as Map<String, dynamic>?;
    if (raw == null) return null;
    return switch (raw['status']) {
      'reached' => const GoalForecastReached(),
      'insufficient' => GoalForecastInsufficient(
        months: (raw['months'] as num?)?.toInt() ?? 0,
      ),
      'ok' => GoalForecastOk(
        months: (raw['months'] as num).toInt(),
        averageMonthlyMinor: BigInt.parse(raw['averageMonthlyMinor'] as String),
        expectedMonth: raw['expectedMonth'] as String,
        targetMonth: raw['targetMonth'] as String?,
        monthsLate: (raw['monthsLate'] as num?)?.toInt(),
      ),
      final other => throw FormatException('status $other'),
    };
  }
}
