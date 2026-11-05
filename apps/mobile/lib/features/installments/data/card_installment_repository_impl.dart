import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/card_installment.dart';
import '../domain/card_installment_repository.dart';

@LazySingleton(as: CardInstallmentRepository)
class CardInstallmentRepositoryImpl implements CardInstallmentRepository {
  CardInstallmentRepositoryImpl(this._api);
  final AuthorizedApi _api;

  static BigInt _money(Object? value) => BigInt.parse(value as String);

  static InstallmentPeriodState _state(Object? value) => switch (value) {
    'past' => InstallmentPeriodState.past,
    'closed' => InstallmentPeriodState.closed,
    _ => InstallmentPeriodState.upcoming,
  };

  static List<InstallmentPeriod> _periods(Object? raw) => List.unmodifiable(
    (raw as List).map((e) {
      final p = e as Map<String, dynamic>;
      return InstallmentPeriod(
        index: p['index'] as int,
        dueOn: p['dueOn'] as String,
        amountMinor: _money(p['amountMinor']),
        state: _state(p['state']),
      );
    }),
  );

  static CardInstallment parse(Map<String, dynamic> json) => CardInstallment(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    transactionId: json['transactionId'] as String,
    accountId: json['accountId'] as String,
    currencyCode: json['currencyCode'] as String,
    totalMinor: _money(json['totalMinor']),
    installmentMinor: _money(json['installmentMinor']),
    installmentCount: json['installmentCount'] as int,
    firstDueOn: json['firstDueOn'] as String,
    active: json['status'] == 'active',
    remainingCount: json['remainingCount'] as int,
    nextDueOn: json['nextDueOn'] as String?,
    nextAmountMinor: json['nextAmountMinor'] == null
        ? null
        : _money(json['nextAmountMinor']),
    version: json['version'] as int,
    purchaseOn: json['purchaseOn'] as String?,
    purchaseMerchant: json['purchaseMerchant'] as String?,
    purchaseCategoryId: json['purchaseCategoryId'] as String?,
    periods: json['periods'] == null ? null : _periods(json['periods']),
  );

  static InstallmentPreview parsePreview(Map<String, dynamic> json) =>
      InstallmentPreview(
        totalMinor: _money(json['totalMinor']),
        installmentMinor: _money(json['installmentMinor']),
        installmentCount: json['installmentCount'] as int,
        firstDueOn: json['firstDueOn'] as String,
        lastDueOn: json['lastDueOn'] as String,
        periods: _periods(json['periods']),
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

  static Map<String, dynamic> _draft(InstallmentDraft draft) => {
    'transactionId': draft.transactionId,
    'installmentCount': draft.installmentCount,
    if (draft.installmentMinor != null)
      'installmentMinor': draft.installmentMinor.toString(),
    'firstDueOn': draft.firstDueOn,
  };

  @override
  Future<Either<AuthFailure, List<CardInstallment>>> list({
    String? accountId,
    bool? active,
  }) {
    final query = [
      if (accountId != null) 'accountId=$accountId',
      if (active != null) 'status=${active ? 'active' : 'closed'}',
    ].join('&');
    return _request(
      'GET',
      query.isEmpty ? 'card-installments' : 'card-installments?$query',
      (json) => List.unmodifiable(
        (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)),
      ),
    );
  }

  @override
  Future<Either<AuthFailure, CardInstallment>> find(String id) =>
      _request('GET', 'card-installments/$id', parse);

  @override
  Future<Either<AuthFailure, InstallmentPreview>> preview(
    InstallmentDraft draft,
  ) => _request(
    'POST',
    'card-installments/preview',
    parsePreview,
    body: _draft(draft),
  );

  @override
  Future<Either<AuthFailure, CardInstallment>> create(
    InstallmentDraft draft, {
    required String clientId,
  }) => _request(
    'POST',
    'card-installments',
    parse,
    body: {'clientId': clientId, ..._draft(draft)},
  );

  @override
  Future<Either<AuthFailure, CardInstallment>> close(CardInstallment plan) =>
      _request(
        'POST',
        'card-installments/${plan.id}/close',
        parse,
        body: {'version': plan.version},
      );

  @override
  Future<Either<AuthFailure, List<InstallmentDue>>> due({
    required String from,
    required String to,
    String? accountId,
  }) => _request(
    'GET',
    [
      'card-installments/due?from=$from&to=$to',
      if (accountId != null) 'accountId=$accountId',
    ].join('&'),
    (json) => List.unmodifiable(
      (json['items'] as List).map((raw) {
        final e = raw as Map<String, dynamic>;
        return InstallmentDue(
          accountId: e['accountId'] as String,
          currencyCode: e['currencyCode'] as String,
          dueMinor: _money(e['dueMinor']),
          planCount: e['planCount'] as int,
        );
      }),
    ),
  );
}
