import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/transaction.dart';
import '../domain/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  TransactionRepositoryImpl(this._api);
  final AuthorizedApi _api;

  TxLeg _leg(Map<String, dynamic> json) => TxLeg(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    accountId: json['accountId'] as String,
    currencyCode: json['currencyCode'] as String,
    amountMinor: BigInt.parse(json['amountMinor'] as String),
    type: TransactionType.values.byName(json['type'] as String),
    occurredOn: json['occurredOn'] as String,
    categoryId: json['categoryId'] as String?,
    notes: json['notes'] as String?,
    merchant: json['merchant'] as String?,
    tagIds: List.unmodifiable(
      (json['tagIds'] as List? ?? const []).cast<String>(),
    ),
    transferGroupId: json['transferGroupId'] as String?,
    deletedAt: json['deletedAt'] == null
        ? null
        : DateTime.parse(json['deletedAt'] as String),
    version: json['version'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  TransactionBundle _bundle(Map<String, dynamic> json) {
    final legs = (json['legs'] as List)
        .map((item) => _leg(item as Map<String, dynamic>))
        .toList();
    legs.sort((a, b) {
      final amount = a.amountMinor.compareTo(b.amountMinor);
      return amount != 0 ? amount : a.id.compareTo(b.id);
    });
    final fx = json['fx'];
    return TransactionBundle(
      legs: List.unmodifiable(legs),
      fx: fx == null
          ? null
          : TransactionFx(
              rate: (fx as Map<String, dynamic>)['rate'] as String,
              quotedAt: fx['quotedAt'] as String,
            ),
    );
  }

  Map<String, dynamic> _body(
    TransactionCommand command, {
    required bool patch,
  }) => {
    if (!patch) 'type': command.type.name,
    if (patch) 'version': command.version,
    'occurredOn': command.occurredOn,
    'categoryId': command.categoryId,
    'notes': command.notes,
    'merchant': command.merchant,
    'tagIds': command.tagIds,
    'legs': [
      for (final leg in command.legs)
        {
          'clientId': leg.clientId,
          'accountId': leg.accountId,
          'currencyCode': leg.currencyCode,
          'amountMinor': leg.amountMinor.toString(),
        },
    ],
    'fx': command.rate == null
        ? null
        : {'rate': command.rate, 'quotedAt': command.quotedAt},
  };

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
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) {
    final search = query.search;
    // Repeated keys for multi-value filters (`accountId=a&accountId=b`).
    final params = <(String, String)>[
      ('page', '${query.page}'),
      ('pageSize', '${query.pageSize}'),
      ('status', query.deleted ? 'deleted' : 'active'),
      if (query.sort != TransactionSort.date) ('sort', query.sort.name),
      if (query.type != null) ('type', query.type!.name),
      if (query.currency != null) ('currency', query.currency!),
      if (search != null) ('search', search),
      if (query.from != null) ('from', query.from!),
      if (query.to != null) ('to', query.to!),
      for (final id in query.accountIds) ('accountId', id),
      for (final id in query.categoryIds) ('categoryId', id),
      for (final id in query.tagIds) ('tagId', id),
    ];
    final path =
        'transactions?${params.map((e) => '${e.$1}=${Uri.encodeQueryComponent(e.$2)}').join('&')}';
    return _request('GET', path, (json) {
      final legs = (json['items'] as List)
          .map((item) => _leg(item as Map<String, dynamic>))
          .toList();
      return TransactionListPage(
        legs: List.unmodifiable(legs),
        page: json['page'] as int,
        total: json['total'] as int,
        summary: _summary(json['summary']),
      );
    });
  }

  @override
  Future<Either<AuthFailure, TransactionBundle>> read(String id) =>
      _request('GET', 'transactions/$id', _bundle);

  @override
  Future<Either<AuthFailure, TransactionBundle>> create(
    TransactionCommand command,
  ) => _request(
    'POST',
    'transactions',
    _bundle,
    body: _body(command, patch: false),
    headers: {'Idempotency-Key': command.legs.first.clientId},
  );

  @override
  Future<Either<AuthFailure, TransactionBundle>> update(
    String id,
    TransactionCommand command,
  ) => _request(
    'PATCH',
    'transactions/$id',
    _bundle,
    body: _body(command, patch: true),
  );

  @override
  Future<Either<AuthFailure, Unit>> remove(String id, int version) =>
      _request('DELETE', 'transactions/$id?version=$version', (_) => unit);

  @override
  Future<Either<AuthFailure, TransactionBundle>> restore(
    String id,
    int version,
  ) => _request(
    'PATCH',
    'transactions/$id',
    _bundle,
    body: {'version': version, 'deleted': false},
  );
}

/// Older servers omit `summary`; treat that as empty.
TransactionSummary _summary(Object? raw) {
  if (raw is! Map<String, dynamic>) return TransactionSummary.empty;
  return TransactionSummary(
    count: raw['count'] as int,
    totals: [
      for (final row in raw['totals'] as List)
        TransactionTotal(
          currency: (row as Map<String, dynamic>)['currency'] as String,
          income: BigInt.parse(row['incomeMinor'] as String),
          expense: BigInt.parse(row['expenseMinor'] as String),
          transferIn: _optionalMinor(row['transferInMinor']),
          transferOut: _optionalMinor(row['transferOutMinor']),
        ),
    ],
  );
}

/// Older servers omit transfer sums; treat that as zero.
BigInt _optionalMinor(Object? raw) =>
    raw == null ? BigInt.zero : BigInt.parse(raw as String);
