import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/recurring_repository.dart';
import '../domain/recurring_rule.dart';

@LazySingleton(as: RecurringRepository)
class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._api);
  final AuthorizedApi _api;

  RecurringRule _parse(Map<String, dynamic> json) => RecurringRule(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    type: json['type'] as String,
    unit: json['unit'] as String,
    interval: json['interval'] as int,
    amountMinor: BigInt.parse(json['amountMinor'] as String),
    currencyCode: json['currencyCode'] as String,
    accountId: json['accountId'] as String,
    categoryId: json['categoryId'] as String?,
    counterAccountId: json['counterAccountId'] as String?,
    counterAmountMinor: json['counterAmountMinor'] == null
        ? null
        : BigInt.parse(json['counterAmountMinor'] as String),
    counterCurrencyCode: json['counterCurrencyCode'] as String?,
    fxRate: json['fxRate'] as String?,
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
    nextExecutionDate: json['nextExecutionDate'] as String,
    active: json['active'] as bool,
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
  Future<Either<AuthFailure, List<RecurringRule>>> list({bool? active}) async {
    final items = <RecurringRule>[];
    final activeQuery = active == null ? '' : '&active=$active';
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'recurring-transactions?pageSize=100&page=$page$activeQuery',
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

  Map<String, dynamic> _body(RecurringDraft draft) => {
    'clientId': draft.clientId,
    'type': draft.type,
    'unit': draft.unit,
    'interval': draft.interval,
    'amountMinor': draft.amountMinor.toString(),
    'currencyCode': draft.currencyCode,
    'accountId': draft.accountId,
    'categoryId': draft.categoryId,
    'counterAccountId': draft.counterAccountId,
    'counterAmountMinor': draft.counterAmountMinor?.toString(),
    'counterCurrencyCode': draft.counterCurrencyCode,
    'fxRate': draft.fxRate,
    'startDate': draft.startDate,
    'endDate': draft.endDate,
    'nextExecutionDate': draft.nextExecutionDate,
    'active': draft.active,
  };

  @override
  Future<Either<AuthFailure, RecurringRule>> create(RecurringDraft draft) =>
      _request(
        'POST',
        'recurring-transactions',
        _parse,
        body: _body(draft),
        headers: {'Idempotency-Key': draft.clientId},
      );

  @override
  Future<Either<AuthFailure, RecurringRule>> update(
    RecurringRule rule, {
    String? unit,
    int? interval,
    BigInt? amountMinor,
    String? currencyCode,
    String? accountId,
    String? categoryId,
    bool clearCategory = false,
    String? counterAccountId,
    bool clearCounter = false,
    BigInt? counterAmountMinor,
    String? counterCurrencyCode,
    String? fxRate,
    bool clearFx = false,
    String? startDate,
    String? endDate,
    bool clearEnd = false,
    String? nextExecutionDate,
    bool? active,
  }) {
    final body = <String, dynamic>{'version': rule.version};
    if (unit != null) body['unit'] = unit;
    if (interval != null) body['interval'] = interval;
    if (amountMinor != null) body['amountMinor'] = amountMinor.toString();
    if (currencyCode != null) body['currencyCode'] = currencyCode;
    if (accountId != null) body['accountId'] = accountId;
    if (clearCategory) {
      body['categoryId'] = null;
    } else if (categoryId != null) {
      body['categoryId'] = categoryId;
    }
    if (clearCounter) {
      body['counterAccountId'] = null;
      body['counterAmountMinor'] = null;
      body['counterCurrencyCode'] = null;
    } else {
      if (counterAccountId != null) body['counterAccountId'] = counterAccountId;
      if (counterAmountMinor != null) {
        body['counterAmountMinor'] = counterAmountMinor.toString();
      }
      if (counterCurrencyCode != null) {
        body['counterCurrencyCode'] = counterCurrencyCode;
      }
    }
    if (clearFx) {
      body['fxRate'] = null;
    } else if (fxRate != null) {
      body['fxRate'] = fxRate;
    }
    if (startDate != null) body['startDate'] = startDate;
    if (clearEnd) {
      body['endDate'] = null;
    } else if (endDate != null) {
      body['endDate'] = endDate;
    }
    if (nextExecutionDate != null) body['nextExecutionDate'] = nextExecutionDate;
    if (active != null) body['active'] = active;
    return _request(
      'PATCH',
      'recurring-transactions/${rule.id}',
      _parse,
      body: body,
    );
  }

  @override
  Future<Either<AuthFailure, Unit>> delete(RecurringRule rule) => _request(
    'DELETE',
    'recurring-transactions/${rule.id}?version=${rule.version}',
    (_) => unit,
  );

  @override
  Future<Either<AuthFailure, RecurringRunResult>> run() => _request(
    'POST',
    'recurring-transactions/run',
    (json) => RecurringRunResult(
      created: json['created'] as int,
      skipped: json['skipped'] as int,
    ),
  );
}
