import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/bill.dart';
import '../domain/bill_repository.dart';

@LazySingleton(as: BillRepository)
class BillRepositoryImpl implements BillRepository {
  BillRepositoryImpl(this._api);
  final AuthorizedApi _api;

  Bill _parse(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    name: json['name'] as String,
    dueOn: json['dueOn'] as String,
    amountMinor: BigInt.parse(json['amountMinor'] as String),
    amountKind: json['amountKind'] as String,
    currencyCode: json['currencyCode'] as String,
    recurringRuleId: json['recurringRuleId'] as String?,
    paidTransactionId: json['paidTransactionId'] as String?,
    paid: json['paid'] as bool,
    overdue: json['overdue'] as bool,
    version: json['version'] as int,
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
  Future<Either<AuthFailure, List<Bill>>> list({String? status}) async {
    final items = <Bill>[];
    final statusQuery = status == null ? '' : '&status=$status';
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'bills?pageSize=100&page=$page$statusQuery',
        (json) => json,
      );
      final error = result.fold<AuthFailure?>((e) => e, (_) => null);
      if (error != null) return left(error);
      try {
        final json = result.getOrElse(() => throw const FormatException());
        final rows = (json['items'] as List)
            .map((item) => _parse(item as Map<String, dynamic>))
            .toList();
        items.addAll(rows);
        if (items.length >= (json['total'] as int)) {
          return right(List.unmodifiable(items));
        }
        if (rows.isEmpty) throw const FormatException();
      } catch (_) {
        return left(const AuthFailure(AuthError.unavailable));
      }
    }
  }

  @override
  Future<Either<AuthFailure, Bill>> create(BillDraft draft) => _request(
    'POST',
    'bills',
    _parse,
    body: {
      'clientId': draft.clientId,
      'name': draft.name,
      'dueOn': draft.dueOn,
      'amountMinor': draft.amountMinor.toString(),
      'amountKind': draft.amountKind,
      'currencyCode': draft.currencyCode,
      'recurringRuleId': draft.recurringRuleId,
    },
    headers: {'Idempotency-Key': draft.clientId},
  );

  @override
  Future<Either<AuthFailure, Bill>> update(
    Bill bill, {
    String? name,
    String? dueOn,
    BigInt? amountMinor,
    String? amountKind,
    String? currencyCode,
    String? recurringRuleId,
    bool clearRule = false,
  }) {
    final body = <String, dynamic>{'version': bill.version};
    if (name != null) body['name'] = name;
    if (dueOn != null) body['dueOn'] = dueOn;
    if (amountMinor != null) body['amountMinor'] = amountMinor.toString();
    if (amountKind != null) body['amountKind'] = amountKind;
    if (currencyCode != null) body['currencyCode'] = currencyCode;
    if (clearRule) {
      body['recurringRuleId'] = null;
    } else if (recurringRuleId != null) {
      body['recurringRuleId'] = recurringRuleId;
    }
    return _request('PATCH', 'bills/${bill.id}', _parse, body: body);
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(Bill bill) => _request(
    'DELETE',
    'bills/${bill.id}?version=${bill.version}',
    (_) => unit,
  );

  @override
  Future<Either<AuthFailure, Bill>> pay(Bill bill, String transactionId) =>
      _request(
        'POST',
        'bills/${bill.id}/pay',
        _parse,
        body: {'version': bill.version, 'transactionId': transactionId},
      );

  @override
  Future<Either<AuthFailure, Bill>> unpay(Bill bill) => _request(
    'POST',
    'bills/${bill.id}/unpay',
    _parse,
    body: {'version': bill.version},
  );
}
