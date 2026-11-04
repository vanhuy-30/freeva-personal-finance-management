import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/debt_repository.dart';
import '../domain/personal_debt.dart';

@LazySingleton(as: DebtRepository)
class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static PersonalDebt parse(Map<String, dynamic> json) => PersonalDebt(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    direction: DebtDirection.values.byName(json['direction'] as String),
    counterparty: json['counterparty'] as String,
    currencyCode: json['currencyCode'] as String,
    principalMinor: _money(json['principalMinor']),
    outstandingMinor: _money(json['outstandingMinor']),
    paidMinor: _money(json['paidMinor']),
    accountId: json['accountId'] as String,
    occurredOn: json['occurredOn'] as String,
    dueDate: json['dueDate'] as String?,
    note: json['note'] as String?,
    status: DebtStatus.values.byName(json['status'] as String),
    archived: json['archivedAt'] != null,
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
  Future<Either<AuthFailure, List<PersonalDebt>>> list() => _request(
    'GET',
    'personal-debts',
    (json) => List.unmodifiable(
      (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)),
    ),
  );

  @override
  Future<Either<AuthFailure, List<DebtTotal>>> totals() => _request(
    'GET',
    'personal-debts/summary',
    (json) => List.unmodifiable(
      (json['totals'] as List).map((raw) {
        final e = raw as Map<String, dynamic>;
        return DebtTotal(
          currencyCode: e['currencyCode'] as String,
          receivableMinor: _money(e['receivableMinor']),
          payableMinor: _money(e['payableMinor']),
          receivableCount: e['receivableCount'] as int,
          payableCount: e['payableCount'] as int,
        );
      }),
    ),
  );

  @override
  Future<Either<AuthFailure, PersonalDebt>> create(DebtDraft draft) => _request(
    'POST',
    'personal-debts',
    parse,
    body: {
      'clientId': draft.clientId,
      'direction': draft.direction.name,
      'counterparty': draft.counterparty.trim(),
      'amountMinor': draft.amountMinor.toString(),
      'accountId': draft.accountId,
      'occurredOn': draft.occurredOn,
      if (draft.dueDate != null) 'dueDate': draft.dueDate,
      if (draft.note != null && draft.note!.trim().isNotEmpty)
        'note': draft.note!.trim(),
    },
  );

  @override
  Future<Either<AuthFailure, PersonalDebt>> update(
    PersonalDebt debt, {
    required String counterparty,
    required String? dueDate,
    required String? note,
  }) => _request(
    'PATCH',
    'personal-debts/${debt.id}',
    parse,
    body: {
      'version': debt.version,
      'counterparty': counterparty,
      'dueDate': dueDate,
      'note': note == null || note.isEmpty ? null : note,
    },
  );

  @override
  Future<Either<AuthFailure, List<DebtPayment>>> payments(String id) =>
      _request(
        'GET',
        'personal-debts/$id/payments',
        (json) => List.unmodifiable(
          (json['items'] as List).map((raw) {
            final e = raw as Map<String, dynamic>;
            return DebtPayment(
              id: e['id'] as String,
              accountId: e['accountId'] as String,
              amountMinor: _money(e['amountMinor']),
              paidOn: e['paidOn'] as String,
            );
          }),
        ),
      );

  @override
  Future<Either<AuthFailure, PersonalDebt>> repay(
    PersonalDebt debt,
    DebtRepay repay,
  ) => _request(
    'POST',
    'personal-debts/${debt.id}/payments',
    parse,
    body: {
      'clientId': repay.clientId,
      'amountMinor': repay.amountMinor.toString(),
      'accountId': repay.accountId,
      'paidOn': repay.paidOn,
    },
  );
}
