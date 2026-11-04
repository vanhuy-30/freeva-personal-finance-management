import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/loan.dart';
import '../domain/loan_repository.dart';

@LazySingleton(as: LoanRepository)
class LoanRepositoryImpl implements LoanRepository {
  LoanRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static BigInt _money(Object? value) => BigInt.parse(value as String);
  static BigInt? _maybe(Object? value) =>
      value == null ? null : BigInt.parse(value as String);

  static LoanStatus _status(String value) => switch (value) {
    'paid_off' => LoanStatus.paidOff,
    'overdue' => LoanStatus.overdue,
    _ => LoanStatus.active,
  };

  static Loan parse(Map<String, dynamic> json) => Loan(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    kind: LoanKind.values.byName(json['kind'] as String),
    name: json['name'] as String,
    currencyCode: json['currencyCode'] as String,
    principalMinor: _money(json['principalMinor']),
    outstandingMinor: _money(json['outstandingMinor']),
    paidMinor: _money(json['paidMinor']),
    percentBps: json['percentBps'] as int,
    interestRateBps: json['interestRateBps'] as int,
    installmentMinor: _maybe(json['installmentMinor']),
    frequency: LoanFrequency.values.byName(json['frequency'] as String),
    startDate: json['startDate'] as String,
    endDate: json['endDate'] as String?,
    nextDueDate: json['nextDueDate'] as String?,
    periodInterestMinor: _money(json['periodInterestMinor']),
    status: _status(json['status'] as String),
    accountId: json['accountId'] as String?,
    archived: json['archivedAt'] != null,
    version: json['version'] as int,
  );

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
  Future<Either<AuthFailure, List<Loan>>> list() => _request(
    'GET',
    'loans',
    (json) => List.unmodifiable(
      (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)),
    ),
  );

  @override
  Future<Either<AuthFailure, List<LoanTotal>>> totals() => _request(
    'GET',
    'loans/summary',
    (json) => List.unmodifiable(
      (json['items'] as List).map((raw) {
        final e = raw as Map<String, dynamic>;
        return LoanTotal(
          currencyCode: e['currencyCode'] as String,
          loanCount: e['loanCount'] as int,
          principalMinor: _money(e['principalMinor']),
          paidMinor: _money(e['paidMinor']),
          outstandingMinor: _money(e['outstandingMinor']),
          dueThisMonthMinor: _money(e['dueThisMonthMinor']),
        );
      }),
    ),
  );

  @override
  Future<Either<AuthFailure, List<LoanScheduleRow>>> schedule(String id) =>
      _request(
        'GET',
        'loans/$id/schedule',
        (json) => List.unmodifiable(
          (json['items'] as List).map((raw) {
            final e = raw as Map<String, dynamic>;
            return LoanScheduleRow(
              index: e['index'] as int,
              dueDate: e['dueDate'] as String?,
              interestMinor: _money(e['interestMinor']),
              principalMinor: _money(e['principalMinor']),
              paymentMinor: _money(e['paymentMinor']),
              outstandingAfterMinor: _money(e['outstandingAfterMinor']),
            );
          }),
        ),
      );

  @override
  Future<Either<AuthFailure, Loan>> create(LoanDraft draft) => _request(
    'POST',
    'loans',
    (json) => parse(json),
    body: {
      'clientId': draft.clientId,
      'kind': draft.kind.name,
      'name': draft.name.trim(),
      'currencyCode': draft.currencyCode,
      'principalMinor': draft.principalMinor.toString(),
      'outstandingMinor': draft.outstandingMinor.toString(),
      'interestRateBps': draft.interestRateBps,
      'installmentMinor': draft.installmentMinor?.toString(),
      'frequency': draft.frequency.name,
      'startDate': draft.startDate,
      'endDate': draft.endDate,
      'nextDueDate': draft.nextDueDate,
      'accountId': draft.accountId,
    },
  );

  @override
  Future<Either<AuthFailure, Loan>> update(
    Loan loan, {
    required LoanKind kind,
    required String name,
    required int interestRateBps,
    required BigInt? installmentMinor,
    required LoanFrequency frequency,
    required String? endDate,
    required String? nextDueDate,
    required String? accountId,
  }) => _request(
    'PATCH',
    'loans/${loan.id}',
    parse,
    body: {
      'version': loan.version,
      'kind': kind.name,
      'name': name,
      'interestRateBps': interestRateBps,
      'installmentMinor': installmentMinor?.toString(),
      'frequency': frequency.name,
      'endDate': endDate,
      'nextDueDate': nextDueDate,
      'accountId': accountId,
    },
  );

  @override
  Future<Either<AuthFailure, Loan>> adjust(
    Loan loan,
    BigInt outstandingMinor,
  ) => _request(
    'POST',
    'loans/${loan.id}/adjust',
    parse,
    body: {
      'outstandingMinor': outstandingMinor.toString(),
      'version': loan.version,
    },
  );

  @override
  Future<Either<AuthFailure, Loan>> pay(Loan loan, LoanPayment payment) =>
      _request(
        'POST',
        'loans/${loan.id}/payments',
        parse,
        body: {
          'clientId': payment.clientId,
          'amountMinor': payment.amountMinor.toString(),
          'principalMinor': payment.principalMinor.toString(),
          'interestMinor': payment.interestMinor.toString(),
          'accountId': payment.accountId,
          'paidOn': payment.paidOn,
        },
      );
}
