import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../auth/data/authorized_api.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/wallet.dart';
import '../domain/wallet_repository.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(this._api);
  final AuthorizedApi _api;
  Wallet _parse(Map<String, dynamic> j) => Wallet(
    id: j['id'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    draft: WalletDraft(
      name: j['name'] as String,
      type: WalletType.values.byName(j['type'] as String),
      currency: j['currencyCode'] as String,
      initialBalance: BigInt.parse(j['initialBalanceMinor'] as String),
      creditLimit: j['creditLimitMinor'] == null
          ? null
          : BigInt.parse(j['creditLimitMinor'] as String),
      closeDay: j['statementCloseDay'] as int?,
      dueDay: j['paymentDueDay'] as int?,
    ),
    balance: BigInt.parse(j['balanceMinor'] as String),
    version: j['version'] as int,
    sortOrder: j['sortOrder'] as int,
    archived: j['archivedAt'] != null,
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
  Future<Either<AuthFailure, List<Wallet>>> load() async {
    final items = <Wallet>[];
    for (var page = 1; ; page++) {
      final result = await _request(
        'GET',
        'financial-accounts?status=all&pageSize=100&page=$page',
        (j) => j,
      );
      final error = result.fold<AuthFailure?>((e) => e, (_) => null);
      if (error != null) return left(error);
      try {
        final json = result.getOrElse(() => throw const FormatException());
        final rows = (json['items'] as List)
            .map((j) => _parse(j as Map<String, dynamic>))
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
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() => _request(
    'GET',
    'profile/options',
    (j) => (j['currencies'] as List)
        .map(
          (c) => WalletCurrency(c['code'] as String, c['minorDigits'] as int),
        )
        .toList(),
  );
  @override
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft d, {
    Wallet? wallet,
    required String clientId,
  }) => _request(
    wallet == null ? 'POST' : 'PATCH',
    wallet == null ? 'financial-accounts' : 'financial-accounts/${wallet.id}',
    _parse,
    body: {
      if (wallet == null) 'clientId': clientId else 'version': wallet.version,
      'name': d.name.trim(),
      'type': d.type.name,
      'currencyCode': d.currency,
      'initialBalanceMinor': d.initialBalance.toString(),
      'creditLimitMinor': d.creditLimit?.toString(),
      'statementCloseDay': d.closeDay,
      'paymentDueDay': d.dueDay,
    },
  );
  @override
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  }) => _request(
    'PATCH',
    'financial-accounts/${wallet.id}',
    _parse,
    body: {
      'version': wallet.version,
      if (archived != null) 'archived': archived,
      if (sortOrder != null) 'sortOrder': sortOrder,
    },
  );
}
